#!/usr/bin/env python3
"""Run one bounded worker at a time; freeze and retain all observations."""
import hashlib,json,pathlib,statistics,subprocess,sys,time
plan=pathlib.Path(sys.argv[1]).resolve();out=pathlib.Path(sys.argv[2]).resolve();mode=sys.argv[3]
assert mode in ['correctness','screen']
out.mkdir(parents=True,exist_ok=False);p=json.loads(plan.read_text())
def ident(f):
 f=pathlib.Path(f).resolve();b=f.read_bytes();return dict(file=str(f),sha256=hashlib.sha256(b).hexdigest(),bytes=len(b))
r=dict(kind=p['kind'],mode=mode,plan=ident(plan),complete=False,**{'pass':False},rows=[])
def save():(out/'report.json').write_text(json.dumps(r,indent=2)+'\n')
save()
try:
 for x in p['inputs']:assert ident(x['file'])['sha256']==x['sha256'],x['file']
 if mode=='screen':
  gate=pathlib.Path(sys.argv[4]).resolve();g=json.loads(gate.read_text());assert g['complete'] and g['pass'] and g['mode']=='correctness';assert g['plan']['sha256']==ident(plan)['sha256']
  r['correctness']=ident(gate)
  oracle={x['id']:{k:x[k] for k in ['observation','output']} for x in json.loads(pathlib.Path(g['rows'][0]['result']['file']).read_text())['rows']}
  selected=[next(x for x in p['cases'] if x['id']==name) for name in ['small','mandelbrot','editdist']]
  p['cases']=selected+selected
  (out/'screen-plan.json').write_text(json.dumps(p,indent=2)+'\n');workerPlan=out/'screen-plan.json'
 else:workerPlan=plan;oracle=None
 for i,role in enumerate(p[mode+'Order']):
  result=out/f'{i}-{role}.json'
  command=['taskset','-c',p['cpu'],p['node']['file'],'--stack-size=4096',f'--max-old-space-size={p["heapMb"]}',p['worker']['file'],str(workerPlan),str(result),role]
  started=time.monotonic()
  with (out/f'{i}.stdout').open('w') as stdout,(out/f'{i}.stderr').open('w') as stderr:proc=subprocess.run(command,stdout=stdout,stderr=stderr,timeout=90)
  row=dict(index=i,role=role,command=command,returncode=proc.returncode,wallSeconds=time.monotonic()-started,result=ident(result));r['rows'].append(row);save();assert proc.returncode==0
  data=json.loads(result.read_text());assert data['pass'] and data['complete']
  actual={x['id']:{k:x[k] for k in ['observation','output']} for x in data['rows']}
  if oracle is None:oracle=actual
  for item in data['rows']:assert {k:item[k] for k in ['observation','output']}==oracle[item['id']],item['id']
 if mode=='screen':
  r['summary']={}
  for name in ['small','mandelbrot','editdist']:
   groups={role:[x['requestMs'] for row in r['rows'] if row['role']==role for x in json.loads(pathlib.Path(row['result']['file']).read_text())['rows'][3:] if x['id']==name] for role in ['baseline','compact']}
   r['summary'][name]={role:dict(samples=xs,median=statistics.median(xs),minimum=min(xs),maximum=max(xs)) for role,xs in groups.items()}
   r['summary'][name]['ratio']=statistics.median(groups['compact'])/statistics.median(groups['baseline'])
 for x in p['inputs']:assert ident(x['file'])['sha256']==x['sha256'],x['file']
 r['complete']=True;r['pass']=True
except Exception as error:r['error']=repr(error)
save();print(json.dumps({k:r[k] for k in ['complete','pass']},indent=2));sys.exit(0 if r['pass'] else 1)
