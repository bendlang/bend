#!/usr/bin/env python3
"""Acquire the ten original libraries against their checked Phase29 outputs."""
from pathlib import Path
import hashlib,json,os,subprocess,sys,time
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
attempt,out=map(lambda x:Path(x).resolve(),sys.argv[1:])
out.mkdir(parents=True,exist_ok=False)
NODE=Path('/home/ai/.nvm/versions/node/v24.18.0/bin/node')
ENV={k:v for k,v in os.environ.items() if not k.startswith('BEND_') and k not in ['NODE_OPTIONS','NODE_PATH']}
def ident(p):
 p=Path(p);return {'file':str(p.resolve()),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
def save(p,x):p.write_text(json.dumps(x,indent=2)+'\n')
parent=ROOT/'selfhost/build/phase29/transfer-04/report.json'
prior=json.loads(parent.read_text());assert prior['complete'] and len(prior['cases'])==10
inputs=[ident(p)for p in [Path(__file__),NODE,attempt/'attempt.json',parent,HERE.parent/'phase26/emit.mjs',HERE.parent/'phase29/execute.mjs']]
report={'kind':'phase30-checked-original-library-acquisition','complete':False,'inputs':inputs,'cpu':4,'scope':'Acquisition and exact scalar execution only; durations are not comparative compiler timing. Baseline labels refer to Phase29, not Phase27.','cases':[]}
save(out/'report.json',report)
def child(args,prefix,timeout=180):
 command=['taskset','-c','4',str(NODE),'--stack-size=4096','--max-old-space-size=1024',*map(str,args)]
 row={'command':command,'complete':False,'timeoutSeconds':timeout};start=time.monotonic()
 with Path(str(prefix)+'.stdout').open('w')as stdout,Path(str(prefix)+'.stderr').open('w')as stderr:
  try:row['exitCode']=subprocess.run(command,cwd=ROOT,env=ENV,stdout=stdout,stderr=stderr,timeout=timeout).returncode
  except subprocess.TimeoutExpired:row['timeout']=True
 row['wallSeconds']=time.monotonic()-start
 row['stdout']=ident(str(prefix)+'.stdout');row['stderr']=ident(str(prefix)+'.stderr')
 lines=Path(str(prefix)+'.stdout').read_text().splitlines()
 if lines:
  try:row['result']=json.loads(lines[-1])
  except json.JSONDecodeError:pass
 row['complete']=row.get('exitCode')==0 and row.get('result',{}).get('complete',False)
 save(Path(str(prefix)+'.json'),row);return row
for case in prior['cases']:
 assert case['complete'];key=case['id'];folder=out/key;folder.mkdir()
 source=Path(case['source']['file']);assert ident(source)==case['source'];inputs.append(ident(source))
 modules={'typescript':case['modules']['upstream'],'phase29':case['modules']['candidate']}
 for file in modules.values():
  receipt=Path(file+'.json');r=json.loads(receipt.read_text())
  assert r['complete'] and (r.get('checked') or r.get('observation',{}).get('checked'))
  assert r['input']['sha256']==case['source']['sha256'] and r['output']['sha256']==ident(file)['sha256']
  inputs.extend([ident(file),ident(receipt)])
 point=case['point'];save(folder/'point.json',point)
 row={'id':key,'source':case['source'],'point':point};report['cases'].append(row)
 row['emission']=child([HERE.parent/'phase26/emit.mjs',attempt,source,folder/'candidate.mjs'],folder/'emission')
 if row['emission']['complete']:
  row['check']=child([HERE.parent/'phase29/execute.mjs','check',folder/'candidate.mjs',folder/'point.json'],folder/'check')
  row['modules']={**modules,'candidate':str(folder/'candidate.mjs')}
 row['complete']=row['emission']['complete'] and row.get('check',{}).get('complete',False)
 save(out/'report.json',report);print(json.dumps({'id':key,'complete':row['complete']}),flush=True)
assert all(ident(p['file'])==p for p in inputs),'Input identity changed'
report['complete']=all(c['complete']for c in report['cases']);save(out/'report.json',report)
if report['complete']:
 save(out/'timing-config.json',{'protocol':'transfer','inputs':[ident(out/'report.json'),*inputs],'cases':[{'id':c['id'],'point':c['point'],'modules':c['modules']}for c in report['cases']]})
raise SystemExit(0 if report['complete']else 1)
