#!/usr/bin/env python3
"""Verify actual private Let emission and adapt unchanged whole-tree controls."""
from pathlib import Path
import hashlib
import importlib.util
import json
import re
import shutil
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
DERIVER = HERE / 'inspect-private-let-derive.py'
CONTROLS = HERE / 'prototype-tree-region-controls.mjs'
spec = importlib.util.spec_from_file_location('actual_private_let_parser', DERIVER)
deriver = importlib.util.module_from_spec(spec)
spec.loader.exec_module(deriver)
parser = deriver.parser
baseline, candidate, out = (Path(x).resolve() for x in sys.argv[1:])


def identity(p):
    p = Path(p).resolve()
    return {'file': str(p), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest(), 'bytes': p.stat().st_size}


def checked(p):
    receipt = Path(str(p) + '.json')
    data = json.loads(receipt.read_text())
    assert data['complete'] and data['observation']['checked']
    assert identity(p)['sha256'] == data['output']['sha256']
    assert identity(data['attempt']['file'])['sha256'] == data['attempt']['sha256']
    return data, [identity(p), identity(receipt), identity(data['attempt']['file'])]


def edit(source, old, new):
    assert source.count(old) == 1
    return source.replace(old, new)


def statements(expr):
    parsed = deriver.binding(expr)
    if parsed is None:
        return 'return ' + expr + ';'
    names, values, body = parsed
    assert not any('$v' + str(i) in expr for i in range(len(names))), 'Unexpected temporary collision'
    temps = ''.join('const $v' + str(i) + '=' + value + ';' for i, value in enumerate(values))
    bindings = ''.join('const ' + name + '=$v' + str(i) + ';' for i, name in enumerate(names))
    return '{' + temps + '{' + bindings + statements(body) + '}}'


before, inputs = checked(baseline)
after, more = checked(candidate)
inputs += more
assert before['input']['sha256'] == after['input']['sha256']
assert before['runtime']['sha256'] == after['runtime']['sha256']
assert before['base']['sha256'] == after['base']['sha256']
assert Path(before['attempt']['file']).parent.name == 'attempt-13'
assert Path(after['attempt']['file']).parent.name == 'attempt-14'
inputs += [identity(p) for p in [Path(__file__), DERIVER, deriver.PARSER, CONTROLS,
                               ROOT / 'design/phase30/private-let-emitter-supplement.md']]
out.mkdir(parents=True, exist_ok=False)
report = {'kind': 'phase30-actual-private-let-emission', 'complete': False, 'pass': False, 'inputs': inputs,
          'scope': 'Checked13→14 emission. Reconstruct only ordinary private helper Let returns using existing temporary spelling; all other bytes must match.', 'patches': []}
shutil.copyfile(Path(__file__), out / 'consumed-actual.py')
try:
    source = baseline.read_text()
    for match in re.finditer(r'function (\$R(?:_\d+)+)\(([^)]*)\)\{', parser.mask(source)):
        start = match.end()
        end = parser.close(source, start - 1)
        body = source[start:end]
        if not body.startswith('return ') or not body.endswith(';'):
            continue
        expression = body[len('return '):-1]
        deriver.lexical_subset(expression)
        if deriver.binding(expression) is None:
            continue
        report['patches'].append({'name': match[1], 'start': start, 'end': end,
                                  'original': body, 'replacement': statements(expression)})
    assert len(report['patches']) == 7
    expected = source
    for patch in reversed(report['patches']):
        expected = expected[:patch['start']] + patch['replacement'] + expected[patch['end']:]
    (out / 'expected-private-let.mjs').write_text(expected)
    assert expected == candidate.read_text(), 'Actual module differs outside the predicted private Let lowering'
    for p, name in [(baseline, 'baseline.mjs'), (candidate, 'candidate.mjs')]:
        shutil.copyfile(p, out / name)
    actual = candidate.read_text()
    marker = '/* private scalar tree */'
    assert actual.count(marker) == 1
    owner = next(line for line in actual.splitlines() if marker in line)
    assert owner.startswith('G["rcol"]=')
    fast_open = owner.index(marker) - 1
    fast_close = parser.close(owner, fast_open)
    callback_open = owner.rfind('function(a,$entered){', 0, fast_open) + len('function(a,$entered){') - 1
    callback_close = parser.close(owner, callback_open)
    sentinel = owner[:fast_open + 1] + 'return "fast";' + owner[fast_close:fast_close + 1] + 'return "generic";' + owner[callback_close:]
    (out / 'candidate-depth-sentinel.mjs').write_text(edit(actual, owner, sentinel))
    controls = edit(CONTROLS.read_text(), "const variants=['baseline','public_leaf','private_leaf'];", "const variants=['baseline','candidate'];")
    start = controls.index("    const original=path.join(dir,variant+'.mjs');let text=")
    end = controls.index('    const m=await import(pathToFileURL(file));', start)
    controls = controls[:start] + "    const file=path.join(dir,'candidate-depth-sentinel.mjs');\n" + controls[end:]
    (out / 'controls.mjs').write_text(controls)
    (out / 'boundary-config.json').write_text(json.dumps({'variants': {name: str(out / (name + '.mjs')) for name in ['baseline', 'candidate']}, 'inputs': [str(out / 'derive.json')]}, indent=2) + '\n')
    assert all(identity(row['file']) == row for row in inputs)
    report.update({'complete': True, 'pass': True, 'fullExpectedByteEquality': True})
except Exception as error:
    report['error'] = repr(error)
    raise
finally:
    (out / 'derive.json').write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps({'complete': True, 'pass': True, 'privateBodies': len(report['patches']), 'out': str(out)}))
