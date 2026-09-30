#!/usr/bin/env python3
"""Compose disjoint, independently retained runtime edits from one checked origin."""
from pathlib import Path
import hashlib
import json
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
config_file, out = (Path(x).resolve() for x in sys.argv[1:])
config = json.loads(config_file.read_text())
resolve = lambda name: (config_file.parent / name).resolve()
inputs = {}


def identity(file):
    file = Path(file).resolve()
    data = file.read_bytes()
    return {'file': str(file), 'sha256': hashlib.sha256(data).hexdigest(), 'bytes': len(data)}


def retain(file, expected=None):
    item = identity(file)
    if expected is not None:
        assert item['sha256'] == expected['sha256'], 'Changed input: ' + str(file)
    assert inputs.get(item['file'], item) == item
    inputs[item['file']] = item
    return item


def save(file, value):
    file.write_text(json.dumps(value, indent=2) + '\n')


manifest_file = resolve(config['attemptManifest'])
manifest = json.loads(manifest_file.read_text())
assert manifest['checked'] and manifest['kind'] == 'bend-development-attempt'
manifest_id = retain(manifest_file)
runtime_id = retain(manifest['runtime']['file'], manifest['runtime'])
runtime = Path(runtime_id['file']).read_text()
edits = []
selected = []
assert 2 <= len(config['interventions']) <= 3
for intervention in config['interventions']:
    name = intervention['name']
    assert name not in selected
    file = resolve(intervention['derive'])
    receipt = json.loads(file.read_text())
    assert receipt['complete']
    retain(file)
    assert any(item['sha256'] == manifest_id['sha256'] for item in receipt['inputs']) or receipt.get('attempt', {}).get('sha256') == manifest_id['sha256']
    for item in receipt['inputs']:
        retain(item['file'], item)
    if name == 'inline_exact':
        assert receipt['kind'] == 'phase30-inline-unregistered-exact-derivation'
        pairs = [(row['old'], row['new']) for row in receipt['rewrites']]
        assert len(pairs) == 2
    elif name == 'actual_method':
        assert receipt['kind'] == 'phase30-actual-method14-derivation'
        pairs = [(receipt['oldInvokeExact'], receipt['newInvokeExact'])]
    elif name in ['generic_matcher', 'fused_matcher']:
        assert receipt['kind'] == 'phase30-generic-partial-prebind-ablation'
        pairs = [(receipt['edit']['original'], receipt['edit']['replacement' if name == 'generic_matcher' else 'fused'])]
    else:
        raise AssertionError('Unsupported intervention: ' + name)
    for old, new in pairs:
        assert old != new and runtime.count(old) == 1
        start = runtime.index(old)
        edits.append({'intervention': name, 'old': old, 'new': new,
                      'sourceStart': start, 'sourceEnd': start + len(old)})
    selected.append(name)
assert config['gates'], 'Independent correctness evidence is required before composition'
for entry in config['gates']:
    file = resolve(entry)
    gate = json.loads(file.read_text())
    assert gate['complete'] and gate['pass'], 'Independent gate did not pass: ' + str(file)
    retain(file)
edits.sort(key=lambda row: row['sourceStart'])
for a, b in zip(edits, edits[1:]):
    assert a['sourceEnd'] <= b['sourceStart'], 'Overlapping mechanisms require a new explicit design'
pieces, cursor, offset = [], 0, 0
for row in edits:
    pieces.extend([runtime[cursor:row['sourceStart']], row['new']])
    row['outputStart'] = row['sourceStart'] + offset
    row['outputEnd'] = row['outputStart'] + len(row['new'])
    offset += len(row['new']) - len(row['old'])
    cursor = row['sourceEnd']
pieces.append(runtime[cursor:])
transformed_runtime = ''.join(pieces)
inverse, cursor = [], 0
for row in edits:
    assert transformed_runtime[row['outputStart']:row['outputEnd']] == row['new']
    inverse.extend([transformed_runtime[cursor:row['outputStart']], row['old']])
    cursor = row['outputEnd']
inverse.append(transformed_runtime[cursor:])
assert ''.join(inverse) == runtime
for file in [Path(__file__), config_file, ROOT / 'design/phase30/runtime-attribution-composition.md']:
    retain(file)
out.mkdir(parents=True, exist_ok=False)
report = {'kind': 'phase30-disjoint-runtime-composition', 'complete': False,
          'attempt': manifest_id, 'runtime': runtime_id, 'interventions': selected,
          'edits': edits, 'inputs': [], 'modules': {},
          'combinedCorrectness': 'pending', 'timing': 'pending',
          'scope': 'Disjoint original-runtime ranges only; suffix bytes identical. Independent gates do not prove combined correctness.'}
try:
    for name, row in config['modules'].items():
        assert name.replace('-', '').replace('_', '').isalnum()
        module = resolve(row['module'])
        receipt_file = resolve(row.get('receipt', row['module'] + '.json'))
        receipt = json.loads(receipt_file.read_text())
        assert receipt['complete'] and receipt['observation']['checked'] and receipt['observation']['status'] == 'ok'
        assert receipt['attempt']['sha256'] == manifest_id['sha256']
        for key in ['api', 'runtime', 'base']:
            assert receipt[key]['sha256'] == manifest[key]['sha256']
            retain(receipt[key]['file'], receipt[key])
        retain(receipt['driver']['file'], receipt['driver'])
        source_id = retain(module, receipt['output'])
        retain(receipt_file)
        retain(receipt['input']['file'], receipt['input'])
        text = module.read_text()
        assert text.startswith(runtime + '\n')
        suffix = text[len(runtime):]
        transformed = transformed_runtime + suffix
        assert ''.join(inverse) + transformed[len(transformed_runtime):] == text
        directory = out / name
        directory.mkdir()
        baseline, candidate = directory / 'baseline.mjs', directory / 'combined.mjs'
        baseline.write_text(text)
        candidate.write_text(transformed)
        report['modules'][name] = {'source': source_id, 'receipt': identity(receipt_file),
                                   'baseline': identity(baseline), 'candidate': identity(candidate)}
    if 'helper' in report['modules']:
        row = report['modules']['helper']
        save(out / 'abi.json', {'baseline': row['baseline']['file'], 'candidate': row['candidate']['file'], 'skipPrototypeControls': False})
    for item in inputs.values():
        assert identity(item['file']) == item, 'Input changed during derivation'
    (out / 'consumed-derive.py').write_bytes(Path(__file__).read_bytes())
    (out / 'consumed-config.json').write_bytes(config_file.read_bytes())
    report['complete'] = True
finally:
    report['inputs'] = list(inputs.values())
    save(out / 'derive.json', report)
print(json.dumps({'complete': True, 'out': str(out), 'interventions': selected}))
