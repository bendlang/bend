#!/usr/bin/env python3
"""Freeze completed harness/reference evidence without modifying original runs."""
import gzip
import hashlib
import io
import json
import pathlib
import tarfile

ROOT = pathlib.Path(__file__).resolve().parents[3]
OUT = pathlib.Path(__file__).resolve().parent
DIRECTORIES = [
    'selfhost/build/phase8/harness-controls-01',
    'selfhost/build/phase8/harness-controls-02',
    'selfhost/build/phase8/reference-frontend-01',
]
SOURCE_FILES = [
    'selfhost/tools/conformance/inventory.mjs',
    'selfhost/tools/conformance/selection.mjs',
    'selfhost/tools/conformance/judge.mjs',
    'selfhost/tools/conformance/run.mjs',
    'selfhost/tools/conformance/target.mjs',
    'selfhost/tools/conformance/semantic-summary.mjs',
    'selfhost/tools/conformance/compare-artifacts.mjs',
    'selfhost/tools/conformance/adapters/upstream.mjs',
    'selfhost/tools/conformance/adapters/typed.mjs',
    'selfhost/tests/conformance/phase8-oracles.test.mjs',
    'selfhost/tests/conformance/phase8-upstream.test.mjs',
    'selfhost/tests/conformance/phase8-comparison.test.mjs',
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
manifest = {'kind':'phase8-conformance-harness-evidence','scope':'Completed reference/harness controls and full frontend reference only; candidate compilation and release provenance are separate.', 'archive':archive.name,'archiveSha256':hashlib.sha256(archive.read_bytes()).hexdigest(),'archiveBytes':archive.stat().st_size,'identities':len(records),'objects':len(objects),'files':records}
(OUT / 'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(json.dumps({k:manifest[k] for k in ['identities','objects','archiveBytes','archiveSha256']},indent=2))
