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
    'selfhost/build/phase8/candidate-execution-01',
    'selfhost/build/phase8/candidate-tcp-elevated-01',
    'selfhost/build/phase8/runtime-foreign-01',
    'selfhost/build/phase8/runtime-foreign-02',
    'selfhost/build/phase8/runtime-foreign-03',
    'selfhost/build/phase8/candidate06-imports-01',
    'selfhost/build/phase8/candidate06-imports-02',
    'selfhost/build/phase8/candidate-03/src',
    'selfhost/build/phase8/candidate-03/tools',
    'selfhost/build/phase8/candidate-06/snapshot/src',
    'selfhost/build/phase8/candidate-06/snapshot/tools',
    'selfhost/tests/conformance/phase8-fixtures',
]
SOURCE_FILES = [
    'selfhost/build/phase8/candidate-03/dist/typed-api.mjs',
    'selfhost/build/phase8/candidate-03/dist/typed-bootstrap-report.json',
    'selfhost/build/phase8/candidate-06/api.mjs',
    'selfhost/build/phase8/candidate-06/api.mjs.bootstrap.json',
    'selfhost/src/runtime/js/test-phase8.mjs',
]
paths = sorted({p for name in DIRECTORIES for p in (ROOT / name).rglob('*') if p.is_file()} | {ROOT / name for name in SOURCE_FILES})
records, objects = [], {}
for p in paths:
    data = p.read_bytes()
    digest = hashlib.sha256(data).hexdigest()
    records.append({'file':str(p.relative_to(ROOT)), 'bytes':len(data), 'sha256':digest})
    objects.setdefault(digest, data)
archive = OUT / 'raw.tar.gz'
if archive.exists() or (OUT / 'manifest.json').exists():
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
manifest = {'kind':'phase8-selected-execution-evidence','scope':'Completed selected JS/interpreter/import controls, all three runtime guard attempts and falsifiers, frozen candidate03 and candidate06 compiler API/source/host inputs. Full frontend vectors and release promotion are separate.', 'archive':archive.name,'archiveSha256':hashlib.sha256(archive.read_bytes()).hexdigest(),'archiveBytes':archive.stat().st_size,'identities':len(records),'objects':len(objects),'files':records}
(OUT / 'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(json.dumps({k:manifest[k] for k in ['identities','objects','archiveBytes','archiveSha256']},indent=2))
