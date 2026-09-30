#!/usr/bin/env python3
"""Retry exact emitted program bytes using each emitter's intended module host."""
from pathlib import Path
import hashlib,json,subprocess,sys,time
source,out=[Path(p).resolve() for p in sys.argv[1:]]
out.mkdir(parents=True,exist_ok=False)
node=Path('/home/ai/.nvm/versions/node/v24.18.0/bin/node')
def ident(p):return {'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
report={'kind':'phase28-program-host-retry','complete':False,'reason':'Upstream js_book emits a CommonJS program using require; initial generic .mjs extension selected the wrong Node host. Emitted bytes remain unchanged.','inputs':[ident(source/'upstream.mjs'),ident(source/'selfhost.mjs'),ident(Path(__file__)),ident(node)],'variants':{}}
for side in ['upstream','selfhost']:
    original=source/(side+'.mjs');program=out/(side+('.cjs' if side=='upstream' else '.mjs'));program.write_bytes(original.read_bytes());assert ident(program)['sha256']==ident(original)['sha256']
    command=['taskset','-c','6',str(node),'--stack-size=4096','--max-old-space-size=1024',str(program)]
    row={'program':ident(program),'original':ident(original),'command':command,'timeoutSeconds':60,'complete':False};begin=time.monotonic()
    stdout=out/(side+'.stdout');stderr=out/(side+'.stderr')
    with stdout.open('wb') as sout,stderr.open('wb') as serr:
        try:row['returncode']=subprocess.run(command,stdout=sout,stderr=serr,timeout=60).returncode
        except subprocess.TimeoutExpired:row['timeout']=True
    row['elapsedSeconds']=time.monotonic()-begin;row['timingScope']='Descriptive acquisition only; concurrent work on another CPU possible.'
    row['stdout']=ident(stdout);row['stderr']=ident(stderr);row['output']=stdout.read_text();row['complete']=row.get('returncode')==0
    report['variants'][side]=row
    (out/'report.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps({'side':side,'complete':row['complete'],'returncode':row.get('returncode'),'output':row['output']}),flush=True)
report['exactStdoutAgreement']=all(v['complete'] for v in report['variants'].values()) and report['variants']['upstream']['output']==report['variants']['selfhost']['output']
report['oracleScope']='Complete differential stdout; no independent interaction-count golden.'
report['complete']=True
for item in report['inputs']:assert ident(Path(item['file']))['sha256']==item['sha256']
(out/'report.json').write_text(json.dumps(report,indent=2)+'\n')
