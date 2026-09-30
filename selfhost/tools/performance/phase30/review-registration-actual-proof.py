#!/usr/bin/env python3
"""Strict checked17 output correspondence; no normalization or compilation."""
from pathlib import Path
import hashlib, json, shutil, sys

config_file, out = map(lambda x: Path(x).resolve(), sys.argv[1:])
config = json.loads(config_file.read_text())
out.mkdir(exist_ok=False)
root = Path(__file__).resolve().parents[4]

def ident(file):
    file = Path(file).resolve()
    data = file.read_bytes()
    return {'file': str(file), 'sha256': hashlib.sha256(data).hexdigest(), 'bytes': len(data)}

def resolve(file):
    p = Path(file)
    return p.resolve() if p.is_absolute() else (config_file.parent / p).resolve()

report = {'kind': 'phase30-checked17-registration-flag-correspondence',
          'complete': False, 'pass': False, 'cases': [], 'inputs': [],
          'scope': 'Complete actual checked17 output equals retained flag derivative; no normalization. No performance or fixed-point claim.'}

def save():
    (out / 'report.json').write_text(json.dumps(report, indent=2) + '\n')

def bind(file, expected=None):
    x = ident(file)
    if expected is not None:
        assert x['sha256'] == expected, str(file)
    report['inputs'].append(x)
    return x

shutil.copyfile(__file__, out / 'consumed-proof.py')
save()
try:
    bind(__file__)
    bind(config_file)
    bind(root / 'design/phase30/registration-flag-independent-validation.md')
    assert config['cases'], 'Nonempty explicitly selected cases required'
    for name, entry in config['cases'].items():
        actual = resolve(entry['actual'])
        derived = resolve(entry['derivation'])
        proof = json.loads(derived.read_text())
        assert proof['complete'] and proof['kind'] == 'phase30-registration-dispatch-derivation'
        flag = proof['variants']['flag']
        assert flag['inverseExact'] and flag['generatedSuffixExact']
        assert len(flag['edits']) == 3
        bind(derived)
        for item in proof['inputs']:
            bind(item['file'], item['sha256'])
        expected = Path(flag['output']['file'])
        bind(expected, flag['output']['sha256'])
        flag_runtime = Path(flag['runtime']['file'])
        bind(flag_runtime, flag['runtime']['sha256'])
        receipt_file = Path(str(actual) + '.json')
        receipt = json.loads(receipt_file.read_text())
        assert receipt['complete'] and receipt['observation']['status'] == 'ok'
        assert receipt['observation']['checked'] is True
        assert Path(receipt['attempt']['file']).parent.name == 'attempt-17'
        bind(receipt_file)
        bind(actual, receipt['output']['sha256'])
        for key in ['attempt', 'input', 'api', 'runtime', 'base', 'driver']:
            bind(receipt[key]['file'], receipt[key]['sha256'])
        original = json.loads((derived.parent / 'checked-emission.json').read_text())
        bind(derived.parent / 'checked-emission.json')
        for key in ['input', 'api', 'base', 'driver']:
            assert receipt[key]['sha256'] == original[key]['sha256'], name + ':' + key
        actual_runtime = Path(receipt['runtime']['file']).read_bytes()
        assert actual_runtime == flag_runtime.read_bytes(), name + ': runtime'
        row = {'name': name, 'actual': ident(actual), 'expectedFlag': ident(expected),
               'checkedReceipt': ident(receipt_file), 'derivation': ident(derived),
               'runtimeExact': True, 'completeBytesEqual': actual.read_bytes() == expected.read_bytes()}
        report['cases'].append(row)
        save()
        assert row['completeBytesEqual'], name
        assert actual.read_bytes().startswith(actual_runtime), name + ': runtime prefix'
    for item in report['inputs']:
        assert ident(item['file']) == item, item['file']
    report['complete'] = report['pass'] = True
except BaseException as error:
    report['error'] = repr(error)
finally:
    save()
print(json.dumps({'complete': report['complete'], 'pass': report['pass'], 'cases': len(report['cases']), 'error': report.get('error')}))
raise SystemExit(0 if report['pass'] else 1)
