#!/usr/bin/env python3
import hashlib,json,pathlib,statistics,subprocess,sys,time
plan=pathlib.Path(sys.argv[1]).resolve();out=pathlib.Path(sys.argv[2]).resolve();out.mkdir(parents=True,exist_ok=False);p=json.loads(plan.read_text())
def ident(f):
 f=pathlib.Path(f);b=f.read_bytes();return dict(file=str(f),sha256=hashlib.sha256(b).hexdigest(),bytes=len(b))
r=dict(kind=p['kind'],plan=ident(plan),complete=False,pass_=False,rows=[])
def save():(out/'report.json').write_text(json.dumps(r,indent=2)+'\n')
save()
try:
 for x in p['inputs']:assert ident(x['file'])['sha256']==x['sha256'],x['file']
 for i,role in enumerate(p['order']):
  result=out/f'{i}-{role}.json';command=[p['node']['file'],'--stack-size=4096','--max-old-space-size=2048',p['worker']['file'],str(plan),str(result),role];start=time.monotonic()
  with (out/f'{i}.stdout').open('w') as stdout,(out/f'{i}.stderr').open('w') as stderr:proc=subprocess.run(command,stdout=stdout,stderr=stderr,timeout=60)
  row=dict(index=i,role=role,command=command,returncode=proc.returncode,wallSeconds=time.monotonic()-start,result=ident(result));r['rows'].append(row);save();assert proc.returncode==0
  data=json.loads(result.read_text());assert data['pass'] and data['complete']
  for item in data['rows']:assert {k:item[k] for k in ['observation','output']}==p['expected'][item['id']],item['id']
 r['summary']={}
 for name in p['expected']:
  groups={role:[x['requestMs'] for row in r['rows'] if row['role']==role for x in json.loads(pathlib.Path(row['result']['file']).read_text())['rows'][3:] if x['id']==name] for role in ['baseline','compact']}
  r['summary'][name]={role:dict(samples=xs,median=statistics.median(xs),minimum=min(xs),maximum=max(xs)) for role,xs in groups.items()};r['summary'][name]['ratio']=statistics.median(groups['compact'])/statistics.median(groups['baseline'])
 for x in p['inputs']:assert ident(x['file'])['sha256']==x['sha256'],x['file']
 r['complete']=True;r['pass']=True
except Exception as error:r['error']=repr(error);r['pass']=False
save();print(json.dumps({k:r[k] for k in ['complete','pass']},indent=2));sys.exit(0 if r['pass'] else 1)
