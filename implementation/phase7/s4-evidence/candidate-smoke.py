#!/usr/bin/env python3
"""Exercise the frozen candidate through the maintained host and local Clang."""
from pathlib import Path
import json, os, subprocess, time, hashlib
root=Path(__file__).resolve().parents[3];area=root/'selfhost/build/phase7/s4';out=area/'candidate-smoke-01';out.mkdir()
m=json.loads((area/'attempt-b01/attempt.json').read_text());node='/home/ai/.nvm/versions/node/v24.18.0/bin/node'
env={k:v for k,v in os.environ.items() if not k.startswith('BEND_') and k!='NODE_OPTIONS'}
env.update(BEND_TYPED_API=m['api']['file'],BEND_TYPED_RUNTIME=m['runtime']['file'],BEND_BASE=m['base']['file'],CC='/tmp/bend-s4-clang19/root/usr/lib/llvm-19/bin/clang',LD_LIBRARY_PATH='/tmp/bend-s4-clang19/root/usr/lib/x86_64-linux-gnu')
fixture=root/'selfhost/tests/conformance/typed-smoke/base-u32.bend'
report={'complete':False,'pass':False,'candidate':m['api'],'runtime':m['runtime'],'base':m['base'],'fixture':{'path':str(fixture),'sha256':hashlib.sha256(fixture.read_bytes()).hexdigest()},'observations':[],'scope':'Correctness smoke, not controlled timing or broad backend conformance.'}
def save(): (out/'report.json').write_text(json.dumps(report,indent=2)+'\n')
try:
 for name,flags,expected in [('check',['--check-only'],'All terms check.\n'),('interpreter',[],'42\n'),('javascript',['--run'],'42\n'),('native',['--run','--cpu'],'42\n')]:
  args=['taskset','-c','0',node,'--stack-size=4096',m['snapshot']['root']+'/tools/typed-driver.mjs',str(fixture),*flags]
  row={'name':name,'argv':args,'started':time.time()};report['observations'].append(row);save()
  with (out/(name+'.stdout')).open('x') as stdout,(out/(name+'.stderr')).open('x') as stderr:
   row['exitCode']=subprocess.run(args,env=env,stdout=stdout,stderr=stderr,timeout=180).returncode
  row['stdout']=(out/(name+'.stdout')).read_text();row['stderr']=(out/(name+'.stderr')).read_text();row['seconds']=time.time()-row['started'];save()
  assert row['exitCode']==0 and row['stdout']==expected and row['stderr']=='',name
 report['complete']=report['pass']=True
except Exception as error:report['error']=repr(error)
save();print(json.dumps(report));raise SystemExit(0 if report['pass'] else 1)
