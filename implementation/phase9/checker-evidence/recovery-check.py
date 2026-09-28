"""Recheck every materialized file and the separately preserved profile stream."""
import gzip
import hashlib
import importlib.util
import json
from pathlib import Path
import sys

sys.dont_write_bytecode = True
root = Path(__file__).resolve().parents[3]
spec = importlib.util.spec_from_file_location('evidence_collector', root / 'implementation/phase8/migration-evidence/collect.py')
collector = importlib.util.module_from_spec(spec)
spec.loader.exec_module(collector)
capsule, recovered, destination = map(Path, sys.argv[1:])
report = {'kind': 'phase9-evidence-recovery-check', 'complete': False, 'pass': False,
          'scope': 'Recovered byte identities and file modes, plus lossless raw-profile stream; no compiler execution.'}
try:
    manifest_path = capsule / 'manifest.json'
    manifest = json.loads(manifest_path.read_text())
    for row in manifest['files']:
        actual = collector.identity(recovered / row['file'])
        for key in ('type', 'bytes', 'sha256', 'mode'):
            assert actual[key] == row[key], (row['file'], key)
        if row['type'] == 'symlink':
            assert actual['target'] == row['target']
    profile_dir = root / 'implementation/phase9/profile-evidence/baseline-01'
    profile = json.loads((profile_dir / 'manifest.json').read_text())
    assert profile['complete'] and len(profile['parts']) == 1
    part = profile['parts'][0]
    compressed = profile_dir / part['file']
    compressed_identity = collector.identity(compressed)
    assert compressed_identity['sha256'] == part['sha256']
    assert compressed_identity['bytes'] == part['bytes']
    digest, count = hashlib.sha256(), 0
    with gzip.open(compressed, 'rb') as stream:
        for block in iter(lambda: stream.read(4 * 1024 * 1024), b''):
            digest.update(block)
            count += len(block)
    assert count == profile['raw']['bytes']
    assert digest.hexdigest() == profile['raw']['sha256']
    report.update({'complete': True, 'pass': True, 'recoveredFiles': len(manifest['files']),
                   'recoveredDirectory': str(recovered.resolve()),
                   'capsuleManifest': {'file': str(manifest_path.resolve()), **collector.identity(manifest_path)},
                   'profileManifest': {'file': str((profile_dir / 'manifest.json').resolve()), **collector.identity(profile_dir / 'manifest.json')},
                   'profileGzip': {'file': str(compressed.resolve()), **compressed_identity},
                   'profileRecoveredStream': {'bytes': count, 'sha256': digest.hexdigest(), 'persistedToDisk': False},
                   'tool': {'file': str(Path(__file__).resolve()), **collector.identity(Path(__file__))}})
except BaseException as error:
    report['error'] = repr(error)
    raise
finally:
    with destination.open('x') as stream:
        json.dump(report, stream, indent=2)
        stream.write('\n')
    print(json.dumps({'complete': report['complete'], 'pass': report['pass'], 'recoveredFiles': report.get('recoveredFiles')}))
