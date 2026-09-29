#!/usr/bin/env python3
"""Run the retained native unit script in a fresh minimal copy of frozen inputs."""
import hashlib,json,os,shutil,subprocess,sys,time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
attempt=Path(sys.argv[1]).resolve();out=Path(sys.argv[2]).resolve();out.mkdir()
node=Path('/home/ai/.nvm/versions/node/v24.18.0/bin/node')
m=json.loads((attempt/'attempt.json').read_text());source=Path(m['snapshot']['root']);project=out/'project'
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
files=['src/core/'+n+'.bend' for n in ['term','index','normalize','graph','reach']]
files+=['src/back/native/'+n for n in (source/'src/back/native/manifest.txt').read_text().splitlines()]
files+=['src/back/native/manifest.txt','src/back/native/tests.mjs','src/runtime/native/runtime.c','tools/assemble.mjs','tools/stage0-library.mjs']
inputs=[]
for name in files:
 original=ROOT/'selfhost'/name if name=='src/back/native/tests.mjs' else source/name
 p=project/name;p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(original,p);inputs.append({'source':str(original),'copy':str(p),'sha256':sha(p)})
shutil.copy2(__file__,out/'consumed-tool.py')
wrapper=out/'node-resources';wrapper.write_text('#!/bin/sh\nexec '+str(node)+' --stack-size=4096 --max-old-space-size=4096 "$@"\n');wrapper.chmod(0o755)
frozen=json.loads((ROOT/'selfhost/build/phase16/wave6-backend-environment-01.json').read_text())
env={k:v for k,v in os.environ.items() if not k.startswith('BEND_') and k not in ['NODE_OPTIONS','NODE_PATH']}
env.update(frozen['environment']);env.update(BEND_UPSTREAM=m['config']['upstream'],BEND_BOOTSTRAP=str(wrapper))
command=['taskset','-c','3',str(wrapper),str(project/'src/back/native/tests.mjs')]
report={'kind':'phase24-frozen-native-unit','inputs':inputs,'attempt':{'file':str(attempt/'attempt.json'),'sha256':sha(attempt/'attempt.json')},'command':command,'environment':{k:env[k] for k in list(frozen['environment'])+['BEND_UPSTREAM','BEND_BOOTSTRAP']},'pass':False}
save=lambda:(out/'report.json').write_text(json.dumps(report,indent=2)+'\n')
save();start=time.monotonic()
try:
 with (out/'stdout.log').open('w') as stdout,(out/'stderr.log').open('w') as stderr:proc=subprocess.run(command,env=env,stdout=stdout,stderr=stderr,timeout=180)
 report.update(exitCode=proc.returncode,passLines=sum(l.startswith('PASS') for l in (out/'stdout.log').read_text().splitlines()))
 report['changedInputs']=[x for x in inputs if sha(x['source'])!=x['sha256'] or sha(x['copy'])!=x['sha256']]
 report['pass']=proc.returncode==0 and not report['changedInputs']
except Exception as e:report['error']=str(e)
report['wallSeconds']=time.monotonic()-start;save();print(json.dumps({k:report.get(k) for k in ['pass','exitCode','passLines','error','wallSeconds']}))
