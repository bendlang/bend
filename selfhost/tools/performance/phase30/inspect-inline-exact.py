#!/usr/bin/env python3
"""Isolate ordinary exact dispatch in checked modules; no generated execution."""
from pathlib import Path
import hashlib
import json
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
config_file, out = (Path(x).resolve() for x in sys.argv[1:])
config = json.loads(config_file.read_text())
resolve = lambda name: (config_file.parent / name).resolve()


def identity(file):
    file = Path(file).resolve()
    data = file.read_bytes()
    return {'file': str(file), 'sha256': hashlib.sha256(data).hexdigest(), 'bytes': len(data)}


def save(file, value):
    Path(file).write_text(json.dumps(value, indent=2) + '\n')


inputs = {}


def retain(file, expected=None):
    item = identity(file)
    if expected is not None:
        assert item['sha256'] == expected['sha256'], 'Changed input: ' + str(file)
    old = inputs.get(item['file'])
    assert old is None or old == item
    inputs[item['file']] = item
    return item


manifest_file = resolve(config['attemptManifest'])
manifest = json.loads(manifest_file.read_text())
assert manifest['checked'] and manifest['kind'] == 'bend-development-attempt'
manifest_id = retain(manifest_file)
runtime_id = retain(manifest['runtime']['file'], manifest['runtime'])
runtime = Path(runtime_id['file']).read_text()
begin = runtime.index('function invokeExact(f,all){\n')
end = runtime.index('function force(x){', begin)
old_invoke = runtime[begin:end]
invoke_prefix = 'function invokeExact(f,all){\n  const code=f.code;\n  if(!exactCodes.has(code)||'
assert old_invoke.startswith(invoke_prefix)
new_invoke = old_invoke.replace(invoke_prefix, 'function invokeExact(f,all,code){\n  if(', 1)
assert '!exactCodes.has(code)' not in new_invoke
old_branch = '  if(all.length===f.arity)return invokeExact(f,all);\n'
new_branch = '''  if(all.length===f.arity){
    const code=f.code;
    if(!exactCodes.has(code))return code.call(f.env,all);
    return invokeExact(f,all,code);
  }
'''
assert runtime.count(old_branch) == 1
for file in [Path(__file__), config_file, ROOT / 'design/phase30/inline-unregistered-exact-entry.md']:
    retain(file)
out.mkdir(parents=True, exist_ok=False)
report = {'kind': 'phase30-inline-unregistered-exact-derivation', 'complete': False,
          'attempt': manifest_id, 'runtime': runtime_id, 'inputs': [], 'modules': {},
          'rewrites': [{'old': old_invoke, 'new': new_invoke}, {'old': old_branch, 'new': new_branch}],
          'scope': 'Only apply exact dispatch and registered invokeExact signature/leading predicate; WeakSet test retained once, registered body unchanged.',
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
        assert text.count(old_invoke) == 1 and text.count(old_branch) == 1
        transformed = text.replace(old_invoke, new_invoke, 1).replace(old_branch, new_branch, 1)
        assert transformed.count(new_invoke) == 1 and transformed.count(new_branch) == 1
        assert transformed.replace(new_invoke, old_invoke, 1).replace(new_branch, old_branch, 1) == text
        directory = out / name
        directory.mkdir()
        baseline, candidate = directory / 'baseline.mjs', directory / 'inline-exact.mjs'
        baseline.write_text(text)
        candidate.write_text(transformed)
        report['modules'][name] = {'source': source_id, 'receipt': identity(receipt_file),
                                   'baseline': identity(baseline), 'candidate': identity(candidate)}
    for item in inputs.values():
        assert identity(item['file']) == item, 'Input changed during derivation'
    if 'helper' in report['modules']:
        row = report['modules']['helper']
        save(out / 'abi.json', {'baseline': row['baseline']['file'], 'candidate': row['candidate']['file'], 'skipPrototypeControls': False})
    (out / 'consumed-derive.py').write_bytes(Path(__file__).read_bytes())
    (out / 'consumed-config.json').write_bytes(config_file.read_bytes())
    report['complete'] = True
finally:
    report['inputs'] = list(inputs.values())
    save(out / 'derive.json', report)
print(json.dumps({'complete': True, 'out': str(out), 'modules': list(report['modules'])}))
