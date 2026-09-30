#!/usr/bin/env python3
"""Reuse only the identical full-check baseline; execute the new candidate."""
import hashlib,json,pathlib,subprocess,sys,time
plan=pathlib.Path(sys.argv[1]).resolve();out=pathlib.Path(sys.argv[2]).resolve();p=json.loads(plan.read_text());out.mkdir(parents=True,exist_ok=False)
def ident(f):
 f=pathlib.Path(f).resolve();b=f.read_bytes();return dict(file=str(f),sha256=hashlib.sha256(b).hexdigest(),bytes=len(b))
r=dict(kind=p['kind'],mode='correctness',plan=ident(plan),complete=False,**{'pass':False},rows=[],reusedBaseline=p['baselineOracle'],priorCorrectness=p['priorCorrectness'])
def save():(out/'report.json').write_text(json.dumps(r,indent=2)+'\n')
save()
try:
 for x in p['inputs']:assert ident(x['file'])['sha256']==x['sha256'],x['file']
 oracle=json.loads(pathlib.Path(p['baselineOracle']['file']).read_text());assert oracle['pass'] and oracle['complete'] and oracle['role']=='baseline'
 assert [x['id'] for x in oracle['rows']]==[x['id'] for x in p['cases']]
 prior=json.loads(pathlib.Path(p['parentPlan']['file']).read_text());assert p['baseline']==prior['baseline'] and p['cases']==prior['cases'] and p['worker']==prior['worker']
 r['rows'].append(dict(role='baseline',reused=True,result=p['baselineOracle']))
 result=out/'compact.json';command=['taskset','-c',p['cpu'],p['node']['file'],'--stack-size=4096',f'--max-old-space-size={p["heapMb"]}',p['worker']['file'],str(plan),str(result),'compact'];started=time.monotonic()
 with (out/'stdout.log').open('w') as stdout,(out/'stderr.log').open('w') as stderr:proc=subprocess.run(command,stdout=stdout,stderr=stderr,timeout=90)
 r['rows'].append(dict(role='compact',command=command,returncode=proc.returncode,wallSeconds=time.monotonic()-started,result=ident(result)));save();assert proc.returncode==0
 data=json.loads(result.read_text());assert data['complete'] and data['pass']
 def observations(report):return [{k:x[k] for k in ['id','observation','output']} for x in report['rows']]
 assert observations(data)==observations(oracle)
 for x in p['inputs']:assert ident(x['file'])['sha256']==x['sha256'],x['file']
 r['complete']=True;r['pass']=True
except Exception as error:r['error']=repr(error)
save();print(json.dumps({k:r[k] for k in ['complete','pass']},indent=2));sys.exit(0 if r['pass'] else 1)
