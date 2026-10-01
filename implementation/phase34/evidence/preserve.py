#!/usr/bin/env python3
"""Capture closed Phase34 observations, then reopen and verify every member."""
from pathlib import Path
import gzip, hashlib, json, tarfile, stat
ROOT=Path(__file__).resolve().parents[3]
SOURCE=ROOT/'selfhost/build/program-diagnostics'
OUT=Path(__file__).resolve().parent

def digest(file):
    h=hashlib.sha256()
    with file.open('rb') as stream:
        for chunk in iter(lambda:stream.read(1024*1024),b''):h.update(chunk)
    return h.hexdigest()

def record(file):
    return dict(path=str(file.relative_to(SOURCE)),bytes=file.stat().st_size,
                mode=stat.S_IMODE(file.stat().st_mode),sha256=digest(file))

files=[]
for file in sorted(SOURCE.rglob('*')):
    if '__pycache__' in file.parts or file.suffix=='.pyc':continue
    if file.is_symlink():raise ValueError('Unexpected symlink: '+str(file))
    if file.is_file():files.append(file)
rows=[record(file) for file in files]
archive=OUT/'validation.tar.gz'
with archive.open('xb') as sink,gzip.GzipFile(fileobj=sink,mode='wb',filename='',mtime=0,compresslevel=6) as compressed:
    with tarfile.open(fileobj=compressed,mode='w|') as tar:
        for file,row in zip(files,rows):
            info=tarfile.TarInfo(row['path']);info.size=row['bytes'];info.mode=row['mode']
            info.mtime=0;info.uid=info.gid=0;info.uname=info.gname=''
            with file.open('rb') as stream:tar.addfile(info,stream)
lookup={row['path']:row for row in rows};seen=set()
with tarfile.open(archive,'r:gz') as tar:
    for member in tar:
        assert member.isfile() and member.name not in seen and member.name in lookup
        expected=lookup[member.name];stream=tar.extractfile(member);h=hashlib.sha256()
        for chunk in iter(lambda:stream.read(1024*1024),b''):h.update(chunk)
        assert member.size==expected['bytes'] and member.mode==expected['mode'] and h.hexdigest()==expected['sha256']
        seen.add(member.name)
assert seen==set(lookup)
assert [record(file) for file in files]==rows,'Evidence changed during capture'
manifest=dict(kind='phase34-validation-capsule',complete=True,reopenedVerified=True,
              source=str(SOURCE),archive=dict(path=archive.name,bytes=archive.stat().st_size,sha256=digest(archive)),
              fileCount=len(rows),logicalBytes=sum(row['bytes'] for row in rows),files=rows,
              exclusions='Only Python bytecode caches; ephemeral synthetic test fixtures are not captured. Synthetic test logs and command/result summaries are retained in controls; the initial profiler run summary was transcribed from its original tool output.')
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(json.dumps({k:manifest[k] for k in ['complete','reopenedVerified','archive','fileCount','logicalBytes']}))
