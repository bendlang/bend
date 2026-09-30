#!/usr/bin/env python3
"""Isolate per-depth reuse of already-private scalar tree continuation frames."""
from pathlib import Path
import hashlib
import importlib.util
import json
import re
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
SOURCE = ROOT / 'selfhost/build/phase30/tree-region-12/candidate.mjs'
PLAN = ROOT / 'design/phase30/scalar-tree-frame-reuse.md'
PARSER = HERE / 'inspect-terminal-region.py'
CONTROLS = ROOT / 'selfhost/build/phase30/tree-compiler-controls-12/actual-controls.mjs'
EXPECTED = 'dbd065e8888b757edbfe49cb707682f4d7c0924ab37a6d4f1e94022e84ea3b3e'


def identity(path):
    path = Path(path).resolve()
    raw = path.read_bytes()
    return {'file': str(path), 'sha256': hashlib.sha256(raw).hexdigest(), 'bytes': len(raw)}


def derive(source):
    assert '$reuseFrame30' not in source
    rows = [line for line in source.splitlines() if line.startswith('G["rcol"]=')]
    assert len(rows) == 1
    row = rows[0]
    assert row.count('/* private scalar tree */') == 1
    pattern = r'\$frames\[\$top\+\+\]=\{args:\[([^\]]+)\],phase:0,left:null\};'
    matches = list(re.finditer(pattern, row))
    assert len(matches) == 1
    push = matches[0][0]
    aliases = [x for x in matches[0][1].split(',') if x]
    assert len(aliases) == 11 and len(set(aliases)) == 11
    assert all(re.fullmatch(r'x\d+', name) for name in aliases)
    pop = '$frames.length=--$top;'
    assert row.count(pop) == 1 and row.count('$frames.length') == 1
    replacement = 'const $reuseFrame30=$frames[$top++];if($reuseFrame30){'
    replacement += ''.join('$reuseFrame30.args[' + str(i) + ']=' + name + ';'
                           for i, name in enumerate(aliases))
    replacement += '$reuseFrame30.phase=0;$reuseFrame30.left=null;}else '
    replacement += '$frames[$top-1]={args:[' + matches[0][1] + '],phase:0,left:null};'
    changed = row.replace(push, replacement).replace(pop, '--$top;')
    assert changed.replace(replacement, push).replace('--$top;', pop) == row
    result = source.replace(row + '\n', changed + '\n')
    assert source.count(row + '\n') == 1
    return result, {'push': push, 'replacementPush': replacement, 'pop': pop,
                    'replacementPop': '--$top;', 'savedParentAliases': aliases,
                    'overwrittenArgumentSlots': len(aliases),
                    'phaseReset': True, 'leftReset': True,
                    'scope': 'One private rcol push/pop only; pool lifetime is one invocation.'}


out = Path(sys.argv[1]).resolve()
receipt_path = Path(str(SOURCE) + '.json')
receipt = json.loads(receipt_path.read_text())
assert identity(SOURCE)['sha256'] == EXPECTED == receipt['output']['sha256']
assert receipt['complete'] and receipt['observation']['checked']
assert Path(receipt['attempt']['file']).parent.name == 'attempt-12'
assert identity(receipt['attempt']['file'])['sha256'] == receipt['attempt']['sha256']
out.mkdir(parents=True, exist_ok=False)
inputs = [identity(p) for p in [SOURCE, receipt_path, receipt['attempt']['file'], PLAN, Path(__file__), PARSER, CONTROLS]]
source = SOURCE.read_text()
candidate, proof = derive(source)
for name, text in [('baseline', source), ('reuse', candidate)]:
    (out / (name + '.mjs')).write_text(text)
spec = importlib.util.spec_from_file_location('frame_review_parser', PARSER)
parser = importlib.util.module_from_spec(spec)
spec.loader.exec_module(parser)
for name, text in [('baseline', source), ('reuse', candidate)]:
    row = next(line for line in text.splitlines() if line.startswith('G["rcol"]='))
    fast_open = row.index('/* private scalar tree */') - 1
    assert row[fast_open] == '{'
    fast_close = parser.close(row, fast_open)
    callback = 'function(a,$entered){'
    callback_open = row.rfind(callback, 0, fast_open) + len(callback) - 1
    callback_close = parser.close(row, callback_open)
    sentinel = row[:fast_open + 1] + 'return "fast";' + row[fast_close:fast_close + 1]
    sentinel += 'return "generic";' + row[callback_close:]
    (out / (name + '-depth-sentinel.mjs')).write_text(text.replace(row, sentinel))
controls = CONTROLS.read_text()
for before, after in [
    ("const variants=['baseline','candidate'];", "const variants=['baseline','reuse'];"),
    ("kind:'phase30-actual-scalar-tree-controls'", "kind:'phase30-tree-frame-reuse-inherited-controls'"),
    ('for(const variant of variants.slice(1)){', 'for(const variant of variants){'),
    ("path.join(dir,'candidate-depth-sentinel.mjs')", "path.join(dir,variant+'-depth-sentinel.mjs')")]:
    assert controls.count(before) == 1, before
    controls = controls.replace(before, after)
(out / 'inherited-controls.mjs').write_text(controls)
for name, path in [('plan.md', PLAN), ('derive.py', Path(__file__)), ('checked-emission.json', receipt_path)]:
    (out / name).write_bytes(path.read_bytes())
outputs = {name: identity(out / (name + '.mjs')) for name in ['baseline', 'reuse']}
diagnostics = [identity(out / name) for name in ['baseline-depth-sentinel.mjs', 'reuse-depth-sentinel.mjs', 'inherited-controls.mjs']]
report = {'kind': 'phase30-scalar-tree-frame-reuse', 'complete': True, 'inputs': inputs,
          'outputs': outputs, 'diagnostics': diagnostics, 'proof': proof, 'compilerChanged': False,
          'maintainedRuntimeChanged': False, 'correctness': 'pending', 'measurement': 'pending'}
(out / 'derive.json').write_text(json.dumps(report, indent=2) + '\n')
for protocol in ['screen', 'confirm']:
    config = {'protocol': protocol, 'inputs': [identity(out / 'derive.json'), *inputs],
              'cases': [{'id': 'private-tree-frame-reuse-original',
                         'point': {'args': [2, 0], 'expected': 887240761},
                         'modules': {name: item['file'] for name, item in outputs.items()}}]}
    (out / (protocol + '.json')).write_text(json.dumps(config, indent=2) + '\n')
config = {'variants': {name: item['file'] for name, item in outputs.items()},
          'inputs': [str(out / 'derive.json'), str(PLAN)]}
(out / 'boundaries.json').write_text(json.dumps(config, indent=2) + '\n')
assert inputs == [identity(item['file']) for item in inputs]
print(json.dumps({'complete': True, 'out': str(out), 'outputs': outputs}))
