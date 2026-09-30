#!/usr/bin/env python3
"""Renew the exact historical method-value intervention on checked current bytes."""
from pathlib import Path
import ast
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
    raw = file.read_bytes()
    return {'file': str(file), 'sha256': hashlib.sha256(raw).hexdigest(), 'bytes': len(raw)}


def retain(file, expected=None):
    item = identity(file)
    if expected is not None:
        assert item['sha256'] == expected['sha256'], 'Changed input: ' + str(file)
    assert inputs.get(item['file'], item) == item
    inputs[item['file']] = item
    return item


def save(file, value):
    Path(file).write_text(json.dumps(value, indent=2) + '\n')


manifest_file = resolve(config['attemptManifest'])
manifest = json.loads(manifest_file.read_text())
assert manifest['checked'] and manifest['kind'] == 'bend-development-attempt'
manifest_id = retain(manifest_file)
runtime_id = retain(manifest['runtime']['file'], manifest['runtime'])
runtime = Path(runtime_id['file']).read_text()
begin = runtime.index('function invokeExact(f,all){\n')
end = runtime.index('function force(x){', begin)
old = runtime[begin:end]
historical_tool = HERE / 'inspect-exact-call-read.py'
historical_receipt = ROOT / 'selfhost/build/phase30/inspection-exact-call-01/derive.json'
tree = ast.parse(historical_tool.read_text())
values = [ast.literal_eval(node.value) for node in tree.body
          if isinstance(node, ast.Assign) and len(node.targets) == 1
          and isinstance(node.targets[0], ast.Name) and node.targets[0].id == 'NEW']
assert len(values) == 1
new = values[0]
history = json.loads(historical_receipt.read_text())
assert history['complete'] and new == history['newInvokeExact']
assert old == history['oldInvokeExact'], 'Runtime policy changed since independent proof'
for file in [Path(__file__), config_file, historical_tool, historical_receipt,
             ROOT / 'design/phase30/actual-method-read-final14.md',
             ROOT / 'design/phase30/exact-entry-call-read.md']:
    retain(file)
out.mkdir(parents=True, exist_ok=False)
report = {'kind': 'phase30-actual-method14-derivation', 'complete': False,
          'attempt': manifest_id, 'runtime': runtime_id, 'inputs': [], 'modules': {},
          'oldInvokeExact': old, 'newInvokeExact': new,
          'scope': 'Only invokeExact; exact historical replacement, unchanged apply/entry/scalar guards/generated bodies.',
          'privatePermission': 'A getter returning the captured native call deliberately changes false to true; public observations remain the oracle.',
          'correctness': 'pending', 'timing': 'pending'}
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
        assert text.startswith(runtime + '\n'), 'Module/runtime prefix mismatch'
        assert text.count(old) == 1
        transformed = text.replace(old, new, 1)
        assert transformed.count(new) == 1 and transformed.replace(new, old, 1) == text
        directory = out / name
        directory.mkdir()
        baseline, candidate = directory / 'baseline.mjs', directory / 'actual-call.mjs'
        baseline.write_text(text)
        candidate.write_text(transformed)
        report['modules'][name] = {'source': source_id, 'receipt': identity(receipt_file),
                                   'baseline': identity(baseline), 'candidate': identity(candidate)}
    if 'helper' in report['modules']:
        row = report['modules']['helper']
        save(out / 'abi.json', {'baseline': row['baseline']['file'], 'candidate': row['candidate']['file'], 'skipPrototypeControls': False})
    controls = HERE / 'inspect-exact-call-controls.mjs'
    text = controls.read_text()
    changes = [("kind:'phase30-exact-call-value-controls'", "kind:'phase30-actual-method14-value-controls'"),
               ("path.resolve(import.meta.dirname,'../phase29/fixture-points.json')",
                json.dumps(str(HERE.parent / 'phase29/fixture-points.json')))]
    for a, b in changes:
        assert text.count(a) == 1
        text = text.replace(a, b)
    assert '[[false],[true]]' in text
    (out / 'method-controls.mjs').write_text(text)
    dispatch = HERE / 'inspect-inline-exact-controls.mjs'
    text = dispatch.read_text()
    dispatch_changes = [("const sides=['baseline','inline-exact']", "const sides=['baseline','actual-call']"),
                        ("kind:'phase30-inline-ordinary-exact-controls'", "kind:'phase30-actual-method14-dispatch-controls'")]
    for a, b in dispatch_changes:
        assert text.count(a) == 1
        text = text.replace(a, b)
    (out / 'dispatch-controls.mjs').write_text(text)
    report['controlsAdapters'] = {'method': [{'old': a, 'new': b} for a, b in changes],
                                 'dispatch': [{'old': a, 'new': b} for a, b in dispatch_changes]}
    retain(controls)
    retain(dispatch)
    for item in inputs.values():
        assert identity(item['file']) == item, 'Input changed during derivation'
    (out / 'consumed-derive.py').write_bytes(Path(__file__).read_bytes())
    (out / 'consumed-config.json').write_bytes(config_file.read_bytes())
    report['complete'] = True
finally:
    report['inputs'] = list(inputs.values())
    save(out / 'derive.json', report)
print(json.dumps({'complete': True, 'out': str(out), 'modules': list(report['modules'])}))
