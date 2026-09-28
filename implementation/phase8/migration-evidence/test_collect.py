#!/usr/bin/env python3
"""Small synthetic evidence controls; no Bend compiler or native jobs."""
import gzip
import importlib.util
import io
import json
from pathlib import Path
import tarfile
import tempfile

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('collect', HERE / 'collect.py')
collect = importlib.util.module_from_spec(spec)
spec.loader.exec_module(collect)
results = []


def check(name, condition):
    assert condition, name
    results.append({'name': name, 'pass': True})


def fails(name, function):
    try:
        function()
    except (AssertionError, ValueError, FileExistsError, OSError):
        results.append({'name': name, 'pass': True})
    else:
        raise AssertionError('Expected rejection: ' + name)


with tempfile.TemporaryDirectory(prefix='phase8-collector-controls-') as temporary:
    root = Path(temporary)
    data = root / 'data'
    data.mkdir()
    (data / 'a').write_bytes(b'shared bytes\n')
    (data / 'a').chmod(0o755)
    (data / 'b').write_bytes((data / 'a').read_bytes())
    (data / 'link').symlink_to('a')
    (data / 'malformed.json').write_text('{negative control')
    dependency = root / 'dependency.mjs'
    dependency.write_text('export const dependency = 1;\n')
    (data / 'report.json').write_bytes((json.dumps({'file': str(dependency), 'sha256': collect.identity(dependency)['sha256']}) + '\r\n').encode())
    cache = data / 'build/typed/cache'
    cache.mkdir(parents=True)
    (cache / 'base.json').write_text('{"derived": true}')
    external = root / 'prior'
    external.mkdir()
    archive = external / 'raw.tar.gz'
    blob = (data / 'a').read_bytes()
    key = collect.digest(blob)
    with tarfile.open(archive, 'w:gz') as tar:
        member = tarfile.TarInfo('objects/' + key)
        member.size = len(blob)
        tar.addfile(member, io.BytesIO(blob))
    prior_manifest = {'archive': 'raw.tar.gz', 'archiveSha256': collect.identity(archive)['sha256'], 'archiveBytes': archive.stat().st_size, 'files': [{'file': 'old/a', 'sha256': key, 'bytes': len(blob)}]}
    (external / 'manifest.json').write_text(json.dumps(prior_manifest))
    selection = {'scope': 'synthetic controls only', 'complete': False, 'include': ['data'], 'externalCapsules': ['prior/manifest.json'], 'externalPrerequisites': [{'path': str(dependency), 'role': 'synthetic tool'}]}
    inventory, objects, _ = collect.inventory(root, selection)
    check('CRLF JSON dependency closure', any(row['file'] == 'dependency.mjs' for row in inventory['files']))
    check('derived cache payload omitted with exact identity', len(inventory['omitted']) == 1 and inventory['omitted'][0]['sha256'] == collect.identity(cache / 'base.json')['sha256'])
    check('prior archive bytes reused', key not in objects and all(row['store'] == 'prior/manifest.json' for row in inventory['files'] if row['sha256'] == key))
    check('malformed negative-control JSON remains captured', inventory['unparsedJson'][0]['file'] == 'data/malformed.json')
    check('external tool bytes recorded without payload selection', inventory['externalPrerequisites'][0]['sha256'] == collect.identity(dependency)['sha256'])
    fails('draft capture rejected', lambda: collect.capture(root, selection, root / 'draft'))
    selection['complete'] = True
    capsule = root / 'capsule'
    verification = collect.capture(root, selection, capsule)
    check('archive byte verification', verification['pass'])
    fails('existing capsule replacement rejected', lambda: collect.capture(root, selection, capsule))
    recovery = root / 'recovery'
    collect.materialize(capsule, recovery, root)
    final = json.loads((capsule / 'manifest.json').read_text())
    check('all files and modes recover exactly', all(collect.identity(recovery / row['file']) == {k: row[k] for k in ('type', 'bytes', 'sha256', 'mode', 'target') if k in row} for row in final['files']))
    check('omitted cache not materialized', not (recovery / 'data/build/typed/cache/base.json').exists())
    fails('existing recovery replacement rejected', lambda: collect.materialize(capsule, recovery, root))
    chained = {**selection, 'externalCapsules': ['prior/manifest.json', 'capsule/manifest.json']}
    supplement = root / 'supplement'
    second = collect.capture(root, chained, supplement)
    check('nested capsule reuses all existing objects', second['objects'] == 0)
    second_recovery = root / 'second-recovery'
    collect.materialize(supplement, second_recovery, root)
    check('nested capsule recovery exact', all(collect.identity(second_recovery / row['file']) == collect.identity(root / row['file']) for row in final['files']))
    fails('missing nested prerequisite rejected', lambda: collect.inventory(root, {**chained, 'externalCapsules': ['capsule/manifest.json']}))
    first_manifest = (capsule / 'manifest.json').read_bytes()
    (capsule / 'manifest.json').write_bytes(first_manifest + b'\n')
    fails('nested prerequisite manifest mutation rejected', lambda: collect.verify(supplement, root))
    (capsule / 'manifest.json').write_bytes(first_manifest)
    payload = (capsule / 'raw.tar.gz').read_bytes()
    (capsule / 'raw.tar.gz').write_bytes(payload[:-1] + bytes([payload[-1] ^ 1]))
    fails('corrupt archive rejected', lambda: collect.verify(capsule, root))
    (capsule / 'raw.tar.gz').write_bytes(payload)
    prior_bytes = (external / 'manifest.json').read_bytes()
    (external / 'manifest.json').write_bytes(prior_bytes + b'\n')
    fails('changed prerequisite manifest rejected', lambda: collect.verify(capsule, root))
    (external / 'manifest.json').write_bytes(prior_bytes)
    manifest_bytes = (capsule / 'manifest.json').read_bytes()
    symlink_row = next(row for row in final['files'] if row['type'] == 'symlink')
    symlink_row['target'] = 'different-safe-target'
    (capsule / 'manifest.json').write_text(json.dumps(final))
    fails('symlink target metadata bound to archived object', lambda: collect.verify(capsule, root))
    final = json.loads(manifest_bytes)
    external_row = next(row for row in final['files'] if row['store'] != 'self')
    external_row['bytes'] += 1
    (capsule / 'manifest.json').write_text(json.dumps(final))
    fails('external file size metadata bound to archived object', lambda: collect.verify(capsule, root))
    final = json.loads(manifest_bytes)
    final['files'][0]['file'] = '../escape'
    (capsule / 'manifest.json').write_text(json.dumps(final))
    fails('escaping recovery name rejected', lambda: collect.verify(capsule, root))
    (capsule / 'manifest.json').write_bytes(manifest_bytes)
    (data / 'unsafe').symlink_to('/tmp')
    unsafe = root / 'unsafe-capsule'
    collect.capture(root, selection, unsafe)
    fails('absolute symlink recovery rejected before creation', lambda: collect.materialize(unsafe, root / 'unsafe-recovery', root))
    check('unsafe recovery destination absent', not (root / 'unsafe-recovery').exists())
    check('restored archive verifies', collect.verify(capsule, root)['pass'])

print(json.dumps({'pass': True, 'checks': len(results), 'scope': 'Synthetic archive integrity and recovery controls only.', 'results': results}, indent=2))
