#!/usr/bin/env python3
"""Gate scaling timing on exact public output of every immutable side/point."""
from pathlib import Path
import hashlib, json, os, subprocess, sys, time
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
directory=Path(sys.argv[1]).resolve();plan_file=directory/'plan.json'
plan=json.loads(plan_file.read_text());assert plan['complete'] and not plan['executed']
out=directory/'public-check';out.mkdir(exist_ok=False)
NODE=Path('/home/ai/.nvm/versions/node/v24.18.0/bin/node')
def identity(p):
 p=Path(p).resolve();return {'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
def save(p,x):p.write_text(json.dumps(x,indent=2)+'\n')
def verify():
 for x in plan['inputs']:assert identity(x['file'])==x,x['file']
 for row in plan['variants'].values():assert identity(row['module']['file'])==row['module']
verify();inputs=[identity(p)for p in [Path(__file__),NODE,plan_file,HERE.parent/'phase29/execute.mjs']]
report={'kind':'phase30-scalar-scaling-public-output-gate','complete':False,'pass':False,
 'inputs':inputs,'scope':'Exact complete public bench results at all4points on3sides. Acquisition only; no comparative timing.', 'steps':[]}
env={k:v for k,v in os.environ.items()if not k.startswith('BEND_') and k not in ['NODE_OPTIONS','NODE_PATH']}
(out/'consumed-check.py').write_bytes(Path(__file__).read_bytes())
for i,point in enumerate(plan['points']):
 for side,variant in plan['variants'].items():
  stem=str(i)+'-'+side;command=['taskset','-c','7',str(NODE),'--stack-size=4096','--max-old-space-size=1024',
   str(HERE.parent/'phase29/execute.mjs'),'check',variant['module']['file'],str(directory/('point-'+str(i)+'.json'))]
  row={'side':side,'point':point,'command':command,'complete':False};report['steps'].append(row);save(out/'report.json',report)
  start=time.monotonic()
  with (out/(stem+'.stdout')).open('w')as stdout,(out/(stem+'.stderr')).open('w')as stderr:
   try:row['exitCode']=subprocess.run(command,cwd=ROOT,env=env,stdout=stdout,stderr=stderr,timeout=120).returncode
   except subprocess.TimeoutExpired:row['timeout']=True
  row['wallSeconds']=time.monotonic()-start
  for suffix in ['stdout','stderr']:row[suffix]=identity(out/(stem+'.'+suffix))
  try:row['result']=json.loads((out/(stem+'.stdout')).read_text().splitlines()[-1])
  except (ValueError,IndexError):pass
  result=row.get('result',{});row['complete']=row.get('exitCode')==0 and result.get('complete') and result.get('firstResult')==point['expected']
  save(out/'report.json',report)
verify();report.update({'complete':True,'pass':len(report['steps'])==12 and all(x['complete']for x in report['steps'])});save(out/'report.json',report)
if report['pass']:
 config_file=directory/'confirm-unvalidated.json';config=json.loads(config_file.read_text())
 config['inputs'] += [identity(config_file),identity(out/'report.json'),*inputs]
 assert not (directory/'confirm.json').exists();save(directory/'confirm.json',config)
print(json.dumps({'complete':True,'pass':report['pass'],'checks':len(report['steps'])}));raise SystemExit(0 if report['pass']else 1)
