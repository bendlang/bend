#!/usr/bin/env python3
"""Freeze closed Phase26 runs and independently read back every archived file."""
import hashlib,json,tarfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3];OUT=Path(__file__).resolve().parent
SOURCE=ROOT/'selfhost/build/phase26';ARCHIVE=OUT/'campaign.tar.gz'
assert not ARCHIVE.exists(),'Use a new capsule identity; never overwrite evidence'
files=sorted(p for p in SOURCE.rglob('*') if p.is_file())
assert not any(p.is_symlink() for p in SOURCE.rglob('*'))
identity=lambda p:{'path':p.relative_to(ROOT).as_posix(),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
items=[identity(p) for p in files]
with tarfile.open(ARCHIVE,'w:gz',compresslevel=9) as archive:
    for p in files:archive.add(p,arcname=p.relative_to(ROOT),recursive=False)
assert items==[identity(p) for p in files],'Input changed while capturing'
restored=[]
with tarfile.open(ARCHIVE,'r:gz') as archive:
    for member in archive:
        assert member.isfile() and not member.name.startswith('/') and '..' not in Path(member.name).parts
        data=archive.extractfile(member).read()
        restored.append({'path':member.name,'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()})
assert restored==items,'Independent decompression differs'
receipt={'complete':True,'archive':identity(ARCHIVE),'members':len(items),'logicalBytes':sum(i['bytes'] for i in items),'recovery':'Independent reopened gzip/tar stream; every member decompressed and compared by exact name, size and SHA256. No extraction or timings rerun.','files':items}
(OUT/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n')
print(json.dumps({k:v for k,v in receipt.items() if k!='files'},indent=2))
