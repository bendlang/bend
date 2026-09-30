#!/usr/bin/env python3
"""Lower only top-level Let-IIFEs in immutable checked private scalar helpers."""
from pathlib import Path
import argparse
import hashlib
import importlib.util
import json
import re
import shutil

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
PARSER = HERE / 'inspect-terminal-region.py'
DESIGN = ROOT / 'design/phase30/private-let-statements.md'
spec = importlib.util.spec_from_file_location('private_let_parser', PARSER)
parser = importlib.util.module_from_spec(spec)
spec.loader.exec_module(parser)
PREFIX = '$let30_'


def identity(path):
    path = Path(path).resolve()
    raw = path.read_bytes()
    return {'file': str(path), 'sha256': hashlib.sha256(raw).hexdigest(), 'bytes': len(raw)}


def lexical_subset(expr):
    # The inherited mask understands ordinary strings and block comments only.
    # Targets in this frozen emission use neither templates nor regexp literals.
    assert '`' not in expr and '//' not in expr
    assert '/*' not in expr.replace('/* primitive */', ''), 'Unexpected block comment'
    masked = parser.mask(expr)
    assert not re.search(r'\b(this|arguments|super|eval|await|yield|function|class)\b|new\.target', masked)
    # Division in these emitted numeric expressions has a preceding operand.
    assert not re.search(r'(^|[=(,:;!&|?])\s*/', masked), 'Ambiguous regexp literal'
    pairs = {'(': ')', '[': ']', '{': '}'}
    stack = []
    for char in masked:
        if char in pairs:
            stack.append(pairs[char])
        elif char in ')]}':
            assert stack and char == stack.pop(), 'Unbalanced expression'
        elif char == ';' and not stack:
            raise AssertionError('Additional top-level statement')
    assert not stack


def binding(expr):
    match = re.match(r'^\(\(((?:x\d+,)+)\)=>', expr)
    if not match:
        assert not re.match(r'^\(\(x\d+\b', expr), 'Unrecognized source Let spelling'
        return None
    params = match[1][:-1].split(',')
    assert len(set(params)) == len(params), 'Duplicate binding'
    end = parser.close(expr, 0)
    assert expr[end + 1:end + 2] == '(' and parser.close(expr, end + 1) == len(expr) - 1
    args = parser.split(expr[end + 2:-1])
    assert len(args) == len(params) and all(arg.strip() and not arg.lstrip().startswith('...') for arg in args)
    body = expr[match.end():end]
    assert body and not body.lstrip().startswith('{'), 'Block arrow outside subset'
    return params, args, body


def lower(expr, counter, rows):
    parsed = binding(expr)
    if parsed is None:
        return 'return ' + expr + ';'
    names, args, body = parsed
    temps = [PREFIX + str(counter[0] + i) for i in range(len(args))]
    counter[0] += len(args)
    rows.append({'binders': names, 'arguments': args, 'body': body, 'temporaries': temps})
    # Finish all RHS evaluations in the outer scope before entering the binder block.
    prefix = ''.join('const ' + temp + '=' + arg + ';' for temp, arg in zip(temps, args))
    locals_ = ''.join('const ' + name + '=' + temp + ';' for name, temp in zip(names, temps))
    return prefix + '{' + locals_ + lower(body, counter, rows) + '}'


def derive(source):
    assert PREFIX not in source, 'Fresh-name collision'
    masked = parser.mask(source)
    edits, skipped, counter = [], [], [0]
    pattern = r'function (\$R(?:_\d+)+)\(([^)]*)\)\{'
    for match in re.finditer(pattern, masked):
        brace = match.end() - 1
        end = parser.close(source, brace)
        body = source[brace + 1:end]
        row = {'name': match[1], 'declaration': match.start(), 'bodyStart': brace + 1, 'bodyEnd': end}
        if not body.startswith('return ') or not body.endswith(';'):
            skipped.append({**row, 'reason': 'existing-statement-or-loop-body'})
            continue
        expr = body[len('return '):-1]
        lexical_subset(expr)
        if binding(expr) is None:
            skipped.append({**row, 'reason': 'no-top-level-source-Let'})
            continue
        bindings = []
        replacement = lower(expr, counter, bindings)
        edits.append({**row, 'start': brace + 1, 'end': end, 'original': body,
                      'replacement': replacement, 'bindings': bindings})
    assert all(a['end'] <= b['start'] for a, b in zip(edits, edits[1:]))
    changed = source
    for edit in reversed(edits):
        assert changed[edit['start']:edit['end']] == edit['original']
        changed = changed[:edit['start']] + edit['replacement'] + changed[edit['end']:]
    restored = changed
    positions, offset = [], 0
    for edit in edits:
        start = edit['start'] + offset
        positions.append((start, start + len(edit['replacement']), edit['original'], edit['replacement']))
        offset += len(edit['replacement']) - len(edit['original'])
    for start, end, original, replacement in reversed(positions):
        assert restored[start:end] == replacement
        restored = restored[:start] + original + restored[end:]
    assert restored == source, 'Exact reconstruction failed'
    return changed, {'edits': edits, 'skipped': skipped, 'helpersChanged': len(edits),
                     'bindingsChanged': counter[0], 'reconstructedOriginal': True}


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('source', type=Path)
    ap.add_argument('out', type=Path)
    args = ap.parse_args()
    source, out = args.source.resolve(), args.out.resolve()
    receipt_file = Path(str(source) + '.json')
    receipt = json.loads(receipt_file.read_text())
    assert receipt['complete'] and receipt['observation']['checked']
    assert receipt['output']['sha256'] == identity(source)['sha256']
    attempt = Path(receipt['attempt']['file'])
    assert attempt.parent.name == 'attempt-12'
    assert receipt['attempt']['sha256'] == identity(attempt)['sha256']
    for key in ['input', 'api', 'runtime', 'base', 'driver']:
        assert identity(receipt[key]['file'])['sha256'] == receipt[key]['sha256']
    out.mkdir(parents=True, exist_ok=False)
    inputs = [identity(p) for p in [Path(__file__), PARSER, DESIGN, source, receipt_file, attempt]]
    inputs += [identity(receipt[key]['file']) for key in ['input', 'api', 'runtime', 'base', 'driver']]
    report = {'kind': 'phase30-private-let-statement-ablation', 'complete': False,
              'compilerChanged': False, 'runtimeChanged': False, 'inputs': inputs}
    for original, name in [(Path(__file__), 'consumed-derive.py'), (PARSER, 'consumed-parser.py'),
                           (DESIGN, 'plan.md'), (source, 'baseline.mjs'), (receipt_file, 'checked-emission.json')]:
        shutil.copyfile(original, out / name)
    try:
        changed, details = derive(source.read_text())
        (out / 'candidate.mjs').write_text(changed)
        report.update(details)
        report['outputs'] = {name: identity(out / (name + '.mjs')) for name in ['baseline', 'candidate']}
        assert all(identity(row['file']) == row for row in inputs)
        report['complete'] = True
    except Exception as error:
        report['error'] = repr(error)
        raise
    finally:
        (out / 'derive.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({'complete': True, 'out': str(out), 'helpersChanged': report['helpersChanged'],
                      'bindingsChanged': report['bindingsChanged']}))


if __name__ == '__main__':
    main()
