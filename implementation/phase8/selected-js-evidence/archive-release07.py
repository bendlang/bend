#!/usr/bin/env python3
"""Freeze completed selected-execution evidence without modifying original runs."""
import gzip
import hashlib
import io
import json
import pathlib
import tarfile

ROOT = pathlib.Path(__file__).resolve().parents[3]
OUT = pathlib.Path(__file__).resolve().parent
DIRECTORIES = [
    'selfhost/build/phase8/release07-foreign-01',
]
SOURCE_FILES = [
    'selfhost/build/phase8/release-07/api.mjs',
    'selfhost/build/phase8/release-07/api.mjs.bootstrap.json',
    'selfhost/build/phase8/release-07/snapshot/src/runtime.mjs',
    'selfhost/build/phase8/release-07/snapshot/src/compiler.json',
    'selfhost/build/phase8/release-07/snapshot/tools/typed-driver.mjs',
    'selfhost/build/phase8/release-07/snapshot/tools/compiler-abi.mjs',
    'selfhost/build/phase8/release-07/snapshot/tools/node-resource-args.mjs',
    'selfhost/build/phase8/release-07/snapshot/tools/assemble.mjs',
    'selfhost/build/phase8/release-07/snapshot/tools/conformance/adapters/typed.mjs',
]
paths = sorted({p for name in DIRECTORIES for p in (ROOT / name).rglob('*') if p.is_file()} | {ROOT / name for name in SOURCE_FILES})
records, objects = [], {}
for p in paths:
    data = p.read_bytes()
    digest = hashlib.sha256(data).hexdigest()
    records.append({'file':str(p.relative_to(ROOT)), 'bytes':len(data), 'sha256':digest})
    objects.setdefault(digest, data)
archive = OUT / 'release07.tar.gz'
if archive.exists() or (OUT / 'release07-manifest.json').exists():
    raise RuntimeError('Refuse to replace existing evidence')
with archive.open('xb') as raw, gzip.GzipFile(filename='', mode='wb', fileobj=raw, mtime=0) as compressed, tarfile.open(fileobj=compressed, mode='w') as tar:
    for digest, data in sorted(objects.items()):
        item = tarfile.TarInfo('objects/' + digest)
        item.size, item.mode, item.mtime = len(data), 0o444, 0
        tar.addfile(item, io.BytesIO(data))
for item in records:
    if hashlib.sha256((ROOT / item['file']).read_bytes()).hexdigest() != item['sha256']:
        raise RuntimeError('Input changed while archiving: ' + item['file'])
with tarfile.open(archive, 'r:gz') as tar:
    for item in tar:
        data = tar.extractfile(item).read()
        if hashlib.sha256(data).hexdigest() != item.name.split('/')[-1]:
            raise RuntimeError('Archive object identity mismatch')
manifest = {'kind':'phase8-selected-execution-evidence','scope':'Final release07 actual 44-row foreign execution gate, API/runtime/host identities and explicit 06-to07 frontend transfer identities. Earlier failed attempts remain in the original raw.tar.gz; full frontend vectors are separate.', 'archive':archive.name,'archiveSha256':hashlib.sha256(archive.read_bytes()).hexdigest(),'archiveBytes':archive.stat().st_size,'identities':len(records),'objects':len(objects),'files':records}
(OUT / 'release07-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(json.dumps({k:manifest[k] for k in ['identities','objects','archiveBytes','archiveSha256']},indent=2))
