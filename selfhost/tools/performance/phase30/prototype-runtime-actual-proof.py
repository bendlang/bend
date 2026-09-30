#!/usr/bin/env python3
"""Exact checked15 output proof with one prospectively declared comment change."""
from pathlib import Path
import hashlib, json, shutil, sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
config_path, out = map(lambda p: Path(p).resolve(), sys.argv[1:])
config = json.loads(config_path.read_text())
out.mkdir(parents=True, exist_ok=False)
OLD = "// Prebind a selected literal arm while preserving apply's field-copy behavior."
NEW = '// Preserve delayed field application for selected literal arms.'
def ident(p):
    p = Path(p).resolve()
    return {'file': str(p), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest(), 'bytes': p.stat().st_size}
def resolve(p):
    p = Path(p)
    return p.resolve() if p.is_absolute() else (config_path.parent / p).resolve()
def save():
    (out / 'report.json').write_text(json.dumps(report, indent=2) + '\n')
report = {'kind': 'phase30-checked15-runtime-exact-emission-proof', 'complete': False, 'pass': False,
          'inputs': [ident(p) for p in [Path(__file__), config_path, ROOT / 'design/phase30/generic-runtime-actual-validation.md']],
          'normalization': {'old': OLD, 'new': NEW, 'scope': 'Exactly one known comment; all remaining module bytes must agree.'}, 'cases': []}
shutil.copyfile(__file__, out / 'consumed-proof.py')
save()
try:
    for name, entry in config['cases'].items():
        actual, expected, derivation = [resolve(entry[k]) for k in ['actual', 'expected', 'derivation']]
        receipt_path = Path(str(actual) + '.json')
        receipt = json.loads(receipt_path.read_text())
        assert receipt['complete'] and receipt['observation']['checked']
        assert Path(receipt['attempt']['file']).parent.name == 'attempt-15'
        assert receipt['output']['sha256'] == ident(actual)['sha256']
        assert receipt['input']['sha256'] == ident(resolve(entry['source']))['sha256']
        proof = json.loads(derivation.read_text())
        assert proof['complete']
        raw = expected.read_text()
        assert raw.count(OLD) == 1 and raw.count(NEW) == 0
        normalized = raw.replace(OLD, NEW)
        target = out / (name + '-expected-normalized.mjs')
        target.write_text(normalized)
        row = {'name': name, 'actual': ident(actual), 'reference': ident(expected), 'normalizedExpected': ident(target),
               'byteEqual': actual.read_bytes() == target.read_bytes()}
        report['cases'].append(row)
        report['inputs'].extend(ident(p) for p in [actual, expected, derivation, receipt_path, resolve(entry['source'])])
        save()
        assert row['byteEqual'], name
    for item in report['inputs']:
        assert ident(item['file']) == item
    report.update({'complete': True, 'pass': True})
except Exception as error:
    report['error'] = repr(error)
    raise
finally:
    save()
print(json.dumps({'complete': True, 'cases': len(report['cases']), 'normalization': 'one exact runtime comment'}))
