#!/usr/bin/env python3
"""Preserve all S4 attempts, inputs, outputs and logs; read back every archived file."""
from pathlib import Path
import gzip, hashlib, io, json, tarfile, shutil
root=Path(__file__).resolve().parents[3];areas=[root/'selfhost/build/phase7/s4-loop',root/'selfhost/build/phase7/s4-loop-02'];out=root/'implementation/phase7/s4-loop-evidence'
archive=out/'raw.tar.gz';manifest=out/'manifest.json'
assert not archive.exists() and not manifest.exists(), 'Do not overwrite evidence'
files=sorted(p for area in areas for p in area.rglob('*') if p.is_file())
records=[]
with archive.open('xb') as raw, gzip.GzipFile(filename='',mode='wb',fileobj=raw,mtime=0) as zipped, tarfile.open(fileobj=zipped,mode='w|') as tar:
 for p in files:
  assert not p.is_symlink(), str(p)
  data=p.read_bytes();name=p.relative_to(root).as_posix();info=tarfile.TarInfo(name);info.size=len(data);info.mode=0o644;info.mtime=0
  tar.addfile(info,io.BytesIO(data));records.append({'path':name,'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()})
byname={r['path']:r for r in records};seen=set()
with tarfile.open(archive,'r:gz') as tar:
 for member in tar:
  assert member.isfile() and member.name not in seen
  data=tar.extractfile(member).read();r=byname[member.name];assert len(data)==r['bytes'] and hashlib.sha256(data).hexdigest()==r['sha256'];seen.add(member.name)
assert seen==set(byname)
d={'kind':'S4-loop-raw-evidence-capsule','complete':True,'readbackVerified':True,'archive':{'file':str(archive.relative_to(root)),'bytes':archive.stat().st_size,'sha256':hashlib.sha256(archive.read_bytes()).hexdigest()},'memberCount':len(records),'uncompressedBytes':sum(r['bytes'] for r in records),'scope':'All files under the failed first loop launcher and corrected four-attempt ABBA run. Original S4 capsule remains immutable; loop source trees/configs/commands/resources and exact runner versions are retained here.','members':records}
manifest.write_text(json.dumps(d,indent=2)+'\n');print(json.dumps({k:v for k,v in d.items() if k!='members'}))
