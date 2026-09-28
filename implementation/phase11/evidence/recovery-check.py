"""Independently rehash every recovered Phase11 file and check recorded modes."""
import importlib.util
import json
from pathlib import Path
import sys
sys.dont_write_bytecode = True
root = Path(__file__).resolve().parents[3]
spec = importlib.util.spec_from_file_location('collector', root / 'implementation/phase8/migration-evidence/collect.py')
collector = importlib.util.module_from_spec(spec)
spec.loader.exec_module(collector)
capsule, recovered, destination = map(Path, sys.argv[1:])
report = {'kind': 'phase11-independent-recovery-check', 'complete': False, 'pass': False,
          'scope': 'Recovered byte identity, type, size, mode and symlink target; no compiler execution.'}
try:
    manifest_file = capsule / 'manifest.json'
    manifest = json.loads(manifest_file.read_text())
    for row in manifest['files']:
        actual = collector.identity(recovered / row['file'])
        for key in ('type', 'bytes', 'sha256', 'mode'):
            assert actual[key] == row[key], (row['file'], key)
        if row['type'] == 'symlink':
            assert actual['target'] == row['target']
    report.update({'complete': True, 'pass': True, 'recoveredFiles': len(manifest['files']),
                   'recoveredDirectory': str(recovered.resolve()),
                   'capsuleManifest': {'file': str(manifest_file.resolve()), **collector.identity(manifest_file)},
                   'tool': {'file': str(Path(__file__).resolve()), **collector.identity(Path(__file__))}})
except BaseException as error:
    report['error'] = repr(error)
    raise
finally:
    with destination.open('x') as stream:
        json.dump(report, stream, indent=2)
        stream.write('\n')
    print(json.dumps({'complete': report['complete'], 'pass': report['pass'], 'recoveredFiles': report.get('recoveredFiles')}))
