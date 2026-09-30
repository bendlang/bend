#!/usr/bin/env python3
"""Run frozen final comparisons serially after all acquisition workers stop."""
from pathlib import Path
import hashlib,json,subprocess,sys,time
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
RAW=ROOT/'selfhost/build/phase29';PLAN=RAW/'final-timing-plan'
receipt=RAW/'final-campaigns.json';assert not receipt.exists()
def ident(p):return {'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
jobs=[('fixture-screen.json','fixture-screen-04'),('fixture-confirm.json','fixture-confirm-04'),
 ('transfer.json','transfer-timing-04'),('transfer-confirm.json','transfer-confirm-04'),
 ('components-confirm.json','components-confirm-04')]
report={'complete':False,'launcher':ident(Path(__file__)),'plan':ident(PLAN/'plan.json'),
 'scope':'Serial clean comparisons; acquisition/build/instrumented execution paused before launch. No process failure is discarded.','runs':[]}
def save():receipt.write_text(json.dumps(report,indent=2)+'\n')
save();started=time.monotonic()
commands=[([sys.executable,str(HERE/'compare.py'),str(PLAN/config),str(RAW/out)],out) for config,out in jobs]
commands.append(([sys.executable,str(HERE/'measure-application.py'),str(RAW/'application-candidate-04/timing-config.json'),str(RAW/'application-timing-04')],'application-timing-04'))
for command,name in commands:
 row={'name':name,'command':command,'started':time.time(),'complete':False};report['runs'].append(row);save()
 print(json.dumps({'started':name}),flush=True);begin=time.monotonic()
 with (RAW/(name+'.stdout')).open('w') as stdout,(RAW/(name+'.stderr')).open('w') as stderr:
  result=subprocess.run(command,cwd=ROOT,stdout=stdout,stderr=stderr)
 row.update(returncode=result.returncode,wallSeconds=time.monotonic()-begin,complete=result.returncode==0)
 save();print(json.dumps(row),flush=True)
 if not row['complete']:raise SystemExit(result.returncode or 1)
report.update(complete=True,wallSeconds=time.monotonic()-started);save()
