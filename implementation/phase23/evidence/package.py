#!/usr/bin/env python3
"""Capture closed Phase23 producers, retaining exact files and modes for recovery."""
from pathlib import Path
import hashlib,json,os,stat,tarfile,time
ROOT=Path(__file__).resolve().parents[3]
OUT=ROOT/'implementation/phase23/evidence'
PATHS=['selfhost/build/phase23','selfhost/tools/performance/phase23','selfhost/tests/phase23-backend','selfhost/build/phase16/wave6-backend-environment-01.json']

def identity(path):
    s=path.lstat(); row={'path':str(path.relative_to(ROOT)),'mode':stat.S_IMODE(s.st_mode)}
    if path.is_symlink():row.update(kind='symlink',target=os.readlink(path))
    elif path.is_dir():row.update(kind='directory')
    elif path.is_file():row.update(kind='file',bytes=s.st_size,sha256=hashlib.sha256(path.read_bytes()).hexdigest())
    else:raise RuntimeError('Unsupported member: '+str(path))
    return row

def main():
    archive=OUT/'phase23-evidence.tar.xz'; manifest=OUT/'manifest.json'
    assert not archive.exists() and not manifest.exists(),'Never overwrite an existing capsule'
    paths=[]
    for name in PATHS:
        root=ROOT/name; assert root.exists(),name; paths.append(root)
        if root.is_dir():paths.extend(root.rglob('*'))
    paths=sorted(set(paths)); members=[identity(p) for p in paths]
    with tarfile.open(archive,'w:xz',preset=3) as tar:
        for p,row in zip(paths,members):
            assert identity(p)==row, str(p)
            tar.add(p,arcname=row['path'],recursive=False)
    assert [identity(p) for p in paths]==members,'Producer changed during capture'
    manifest.write_text(json.dumps({'kind':'phase23-closed-evidence-capsule','roots':PATHS,'created':time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime()),'archive':{'file':archive.name,'bytes':archive.stat().st_size,'sha256':hashlib.sha256(archive.read_bytes()).hexdigest()},'members':members,'scope':'Every member of listed closed Phase23 producers, including unsuccessful attempts; old external prerequisites are separately listed. Recovery does not create new experimental observations.'},indent=2)+'\n')
    print(json.dumps({'archiveBytes':archive.stat().st_size,'members':len(members),'files':sum(x['kind']=='file' for x in members),'manifest':str(manifest)}))
if __name__=='__main__':main()
