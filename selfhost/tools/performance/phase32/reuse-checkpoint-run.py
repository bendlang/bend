#!/usr/bin/env python3
import hashlib,json,pathlib,subprocess,sys,time
plan=pathlib.Path(sys.argv[1]).resolve();out=pathlib.Path(sys.argv[2]).resolve();out.mkdir(parents=True,exist_ok=False);p=json.loads(plan.read_text())
def ident(f):
 f=pathlib.Path(f).resolve();b=f.read_bytes();return dict(file=str(f),sha256=hashlib.sha256(b).hexdigest(),bytes=len(b))
r=dict(kind=p['kind'],plan=ident(plan),complete=False,**{'pass':False},rows=[])
def save():(out/'report.json').write_text(json.dumps(r,indent=2)+'\n')
save()
try:
 for x in p['inputs']:assert ident(x['file'])['sha256']==x['sha256'],x['file']
 oracle=None
 # Bound retention lifetime by resetting at each independent source family.
 groups=[p['cases'][:9],p['cases'][9:15],p['cases'][15:]]
 for group,cases in enumerate(groups):
  local=dict(p,cases=cases);localPlan=out/f'group-{group}.json';localPlan.write_text(json.dumps(local,indent=2)+'\n')
  for role in ['baseline','checkpoint']:
   result=out/f'{group}-{role}.json';command=['taskset','-c',p['cpu'],p['node']['file'],'--stack-size=4096',f'--max-old-space-size={p["heapMb"]}',p['worker']['file'],str(localPlan),str(result),role];started=time.monotonic()
   with (out/f'{group}-{role}.stdout').open('w') as stdout,(out/f'{group}-{role}.stderr').open('w') as stderr:proc=subprocess.run(command,stdout=stdout,stderr=stderr,timeout=90)
   row=dict(group=group,role=role,command=command,returncode=proc.returncode,wallSeconds=time.monotonic()-started,result=ident(result));r['rows'].append(row);save();assert proc.returncode==0
   data=json.loads(result.read_text());assert data['complete'] and data['pass']
   actual=[{k:x[k] for k in ['id','observation','output']} for x in data['rows']]
   if role=='baseline':oracle=actual
   else:assert actual==oracle,group
 for x in p['inputs']:assert ident(x['file'])['sha256']==x['sha256'],x['file']
 r['complete']=True;r['pass']=True
except Exception as error:r['error']=repr(error)
save();print(json.dumps({k:r[k] for k in ['complete','pass']},indent=2));sys.exit(0 if r['pass'] else 1)
