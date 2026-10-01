#!/usr/bin/env python3
"""Root-only serial executor for a frozen Phase35 plan; never promotes implicitly."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import time

ap=argparse.ArgumentParser(description=__doc__)
ap.add_argument('plan_directory',type=Path)
ap.add_argument('--stage',choices=['preinstall','owner','postinstall'],default='preinstall')
ap.add_argument('--start',help='Resume at this exact command; existing outputs are never overwritten')
ap.add_argument('--out',type=Path,required=True,help='New serial-launcher receipt directory')
a=ap.parse_args();base=a.plan_directory.resolve();out=a.out.resolve();out.mkdir(parents=True,exist_ok=False)
planfile=base/'plan.json';plan=json.loads(planfile.read_text())
assert plan['complete'] and not plan['executed'] and plan['kind']=='phase35-final-integration-plan'
def identity(file):
 file=Path(file).resolve();h=hashlib.sha256()
 with file.open('rb') as stream:
  for part in iter(lambda:stream.read(2**20),b''):h.update(part)
 return dict(file=str(file),sha256=h.hexdigest(),bytes=file.stat().st_size)
def verify():
 for row in plan['inputs']:assert identity(row['file'])==row,row['file']
verify()
stages=['owner','preinstall'] if a.stage=='preinstall' else [a.stage]
rows=[r for stage in stages for r in plan['commands'] if r['stage']==stage]
assert rows,'No commands for stage'
if a.start:
 names=[r['name'] for r in rows];assert names.count(a.start)==1
 rows=rows[names.index(a.start):]
report=dict(kind='phase35-serial-final-gate-launch',complete=False,stage=a.stage,plan=identity(planfile),producer=identity(__file__),steps=[])
(out/'consumed-run.py').write_bytes(Path(__file__).read_bytes())
def save():(out/'report.json').write_text(json.dumps(report,indent=2)+'\n')
env={k:v for k,v in os.environ.items() if not k.startswith('BEND_') and k not in ['NODE_OPTIONS','NODE_PATH']}
save()
try:
 for row in rows:
  verify();command=row['supervisedCommand'];name=row['name'];print(json.dumps(dict(start=name,stage=a.stage)),flush=True)
  item=dict(name=name,command=command,complete=False,started=time.time());report['steps'].append(item);save()
  with (out/(name+'.stdout')).open('x') as stdout,(out/(name+'.stderr')).open('x') as stderr:
   process=subprocess.run(command,stdout=stdout,stderr=stderr,env=env,cwd=Path(__file__).resolve().parents[4])
  item.update(returncode=process.returncode,finished=time.time(),stdout=identity(out/(name+'.stdout')),stderr=identity(out/(name+'.stderr')))
  item['complete']=process.returncode==0;save();assert item['complete'],name+' failed; preserved output and supervisor receipt'
  verify()
 report['complete']=True
except Exception as error:
 report['error']=repr(error);raise
finally:save()
print(json.dumps(dict(complete=True,stage=a.stage,steps=len(rows),report=str(out/'report.json'))))
