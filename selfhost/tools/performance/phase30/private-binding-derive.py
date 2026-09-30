#!/usr/bin/env python3
"""Freeze private-helper binding alternatives; public/runtime bytes stay intact."""
from pathlib import Path
import hashlib
import importlib.util
import json
import re
import shutil
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
PARSER = HERE / 'inspect-terminal-region.py'
PLAN = ROOT / 'design/phase30/private-helper-binding.md'
spec = importlib.util.spec_from_file_location('private_binding_parser', PARSER)
parser = importlib.util.module_from_spec(spec)
spec.loader.exec_module(parser)


def identity(p):
    p = Path(p).resolve()
    raw = p.read_bytes()
    return {'file': str(p), 'sha256': hashlib.sha256(raw).hexdigest(), 'bytes': len(raw)}


def derive(source, arrow):
    edits = []
    # Private bindings occur only as declarations or saturated direct calls.
    masked = parser.mask(source)
    for use in re.finditer(r'\$R(?:_\d+)+', masked):
        assert masked[use.end():].lstrip().startswith('('), use.group()
    for match in re.finditer(r'function (\$R(?:_\d+)+)\(([^)]*)\)\{', source):
        start, brace = match.start(), match.end() - 1
        end = parser.close(source, brace) + 1
        original = source[start:end]
        body = source[brace:end]
        assert not re.search(r'\b(this|arguments|super)\b|new\.target', parser.mask(body))
        replacement = 'const ' + match[1] + '='
        replacement += '(' + match[2] + ')=>' if arrow else 'function(' + match[2] + ')'
        replacement += body + ';'
        edits.append({'start': start, 'end': end, 'original': original, 'replacement': replacement})
    assert edits
    assert all(a['end'] <= b['start'] for a, b in zip(edits, edits[1:]))
    changed = source
    for edit in reversed(edits):
        changed = changed[:edit['start']] + edit['replacement'] + changed[edit['end']:]
    restored = changed
    # Repeated copies of the same helper are legitimate; reconstruct by offsets.
    offset = 0
    positions = []
    for edit in edits:
        start = edit['start'] + offset
        positions.append((start, start + len(edit['replacement']), edit['original']))
        offset += len(edit['replacement']) - len(edit['original'])
    for start, end, original in reversed(positions):
        restored = restored[:start] + original + restored[end:]
    assert restored == source
    return changed, edits


source, out = map(lambda x: Path(x).resolve(), sys.argv[1:])
receipt_path = Path(str(source) + '.json')
receipt = json.loads(receipt_path.read_text())
assert receipt['complete'] and receipt['observation']['checked']
assert receipt['output']['sha256'] == identity(source)['sha256']
attempt = Path(receipt['attempt']['file'])
assert attempt.parent.name == 'attempt-12'
assert receipt['attempt']['sha256'] == identity(attempt)['sha256']
out.mkdir(parents=True, exist_ok=False)
inputs = [identity(p) for p in [Path(__file__), PARSER, PLAN, source, receipt_path, attempt]]
for before, after in [(Path(__file__), 'consumed-derive.py'), (PLAN, 'plan.md'),
                      (source, 'baseline.mjs'), (receipt_path, 'checked-emission.json')]:
    shutil.copyfile(before, out / after)
report = {'complete': False, 'kind': 'phase30-private-helper-binding-ablation',
          'inputs': inputs, 'compilerChanged': False, 'runtimeChanged': False, 'variants': {}}
try:
    for variant, arrow in [('constant_function', False), ('constant_arrow', True)]:
        text, edits = derive(source.read_text(), arrow)
        target = out / (variant + '.mjs')
        target.write_text(text)
        report['variants'][variant] = {'output': identity(target), 'edits': edits}
    assert all(identity(item['file']) == item for item in inputs)
    report['complete'] = True
finally:
    (out / 'derive.json').write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps({'complete': True, 'out': str(out), 'helpers': len(edits)}))
