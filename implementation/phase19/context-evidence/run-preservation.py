#!/usr/bin/env python3
"""Capture then independently recover, retaining process output and exit state."""
from pathlib import Path
import datetime, hashlib, json, subprocess, sys, time

ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).resolve().parent
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def now():return datetime.datetime.now(datetime.timezone.utc).isoformat()
review=json.loads((HERE/'selection-review.json').read_text());assert review['complete'] and review['pass']
assert sha(HERE/'capsule-01/inventory.json')==review['inventorySha256']
recovery=ROOT/'selfhost/tools/performance/phase16/compact-recover.py'
assert sha(recovery)=='654bcf4435c7b02d329299aa3f4a71aed46c122b556ecd06bfbccece15972234'
report={'kind':'phase19-context-capture-and-recovery-processes','complete':False,'pass':False,
 'started':now(),'toolSha256':sha(__file__),'affinity':[3],
 'selectionReviewSha256':sha(HERE/'selection-review.json'),'processes':[]}
try:
 for name,args in [
  ('capture',[sys.executable,'selfhost/tools/performance/phase19/context-preserve.py','capture','implementation/phase19/context-evidence/capsule-01']),
  ('recovery',[sys.executable,str(recovery),'implementation/phase19/context-evidence/capsule-01','implementation/phase19/context-evidence/recovery-01.json'])]:
  started=now();t=time.monotonic()
  with (HERE/(name+'.stdout')).open('xb') as out,(HERE/(name+'.stderr')).open('xb') as err:
   p=subprocess.run(args,cwd=ROOT,stdout=out,stderr=err,timeout=600)
  row={'name':name,'argv':args,'cwd':str(ROOT),'started':started,'finished':now(),
   'wallSeconds':time.monotonic()-t,'exitCode':p.returncode if p.returncode>=0 else None,
   'signal':-p.returncode if p.returncode<0 else None,'timeout':False,
   'stdout':{'file':str((HERE/(name+'.stdout')).relative_to(ROOT)),'sha256':sha(HERE/(name+'.stdout'))},
   'stderr':{'file':str((HERE/(name+'.stderr')).relative_to(ROOT)),'sha256':sha(HERE/(name+'.stderr'))}}
  report['processes'].append(row)
  assert p.returncode==0,name+' failed'
  if name=='capture':
   m=json.loads((HERE/'capsule-01/manifest.json').read_text());assert m['complete'] and m['captured']
  else:
   result=json.loads((HERE/'recovery-01.json').read_text());assert result['complete'] and result['pass']
 report.update(complete=True,pass_=True)
 report['pass']=report.pop('pass_')
except Exception as e:
 report['error']=repr(e)
finally:
 report['finished']=now()
 with (HERE/'processes-01.json').open('x') as f:json.dump(report,f,indent=2);f.write('\n')
print(json.dumps({'complete':report['complete'],'pass':report['pass'],'processes':len(report['processes'])}))
raise SystemExit(0 if report['pass'] else 1)
