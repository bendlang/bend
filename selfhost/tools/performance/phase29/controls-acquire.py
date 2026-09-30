#!/usr/bin/env python3
"""Checked source controls: acquire three outputs, then compare every scalar."""
from pathlib import Path
import hashlib,json,os,subprocess,sys,time
TOOLS=Path(__file__).resolve().parent
ROOT=TOOLS.parents[3]
NODE=Path('/home/ai/.nvm/versions/node/v24.18.0/bin/node')
baseline,candidate,out=[Path(p).resolve() for p in sys.argv[1:]]
out.mkdir(parents=True,exist_ok=False)
def identity(file):
    return {'file':str(file),'sha256':hashlib.sha256(file.read_bytes()).hexdigest(),'bytes':file.stat().st_size}
def save(file,value):
    file.write_text(json.dumps(value,indent=2)+'\n')
source=TOOLS/'controls-primitives.bend'
inputs=[identity(p) for p in [Path(__file__),NODE,source,TOOLS/'controls-run.mjs',TOOLS/'controls-operations.json',baseline/'attempt.json',candidate/'attempt.json',TOOLS.parent/'phase25/emit.mjs',TOOLS.parent/'phase26/emit.mjs']]
report={'kind':'phase29-checked-primitive-acquisition','complete':False,'pass':False,'inputs':inputs,'cpu':4,'heapMb':1024,'stackKb':4096,'timeoutSeconds':120,'steps':[]}
save(out/'report.json',report)
env={k:v for k,v in os.environ.items() if not k.startswith('BEND_') and k not in ['NODE_OPTIONS','NODE_PATH']}
def child(args,name):
    command=['taskset','-c','4',str(NODE),'--stack-size=4096','--max-old-space-size=1024',*map(str,args)]
    row={'name':name,'command':command,'complete':False,'timingScope':'Descriptive acquisition/validation only, not comparative timing.'}
    report['steps'].append(row)
    started=time.monotonic()
    stdout=out/(name+'.stdout');stderr=out/(name+'.stderr')
    with stdout.open('wb') as sout,stderr.open('wb') as serr:
        try:row['returncode']=subprocess.run(command,stdout=sout,stderr=serr,env=env,timeout=120).returncode
        except subprocess.TimeoutExpired:row['timeout']=True
    row['processSeconds']=time.monotonic()-started
    row['stdout']=identity(stdout);row['stderr']=identity(stderr)
    lines=stdout.read_text().splitlines()
    if lines:
        try:row['result']=json.loads(lines[-1]);row['complete']=row.get('returncode')==0 and row['result'].get('complete',False)
        except json.JSONDecodeError:pass
    save(out/'report.json',report)
    print(json.dumps({'name':name,'complete':row['complete'],'processSeconds':row['processSeconds']}),flush=True)
    return row['complete']
modules={side:str(out/(side+'.mjs')) for side in ['upstream','baseline','candidate']}
okay=True
for side in modules:
    args=[TOOLS.parent/'phase25/emit.mjs','upstream',source,modules[side]] if side=='upstream' else [TOOLS.parent/'phase26/emit.mjs',baseline if side=='baseline' else candidate,source,modules[side]]
    okay=child(args,side+'-emit') and okay
if okay:
    config=out/'comparison.json';save(config,{'modules':modules})
    okay=child([TOOLS/'controls-run.mjs',config,out/'comparison'],'comparison') and okay
    if okay:okay=json.loads((out/'comparison/report.json').read_text()).get('pass',False)
report['changedInputs']=[x for x in inputs if identity(Path(x['file']))['sha256']!=x['sha256']]
report['complete']=True;report['pass']=okay and not report['changedInputs']
save(out/'report.json',report)
sys.exit(0 if report['pass'] else 1)
