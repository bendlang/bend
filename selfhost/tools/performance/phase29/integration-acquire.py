#!/usr/bin/env python3
"""Checked acquisition of a real compiler component and whole HVM demo.

Every child runs on CPU6. Times are descriptive acquisition costs only.
"""
from pathlib import Path
import hashlib,json,os,subprocess,sys,time
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
NODE=Path('/home/ai/.nvm/versions/node/v24.18.0/bin/node')
attempt,componentOut,applicationOut=[Path(p).resolve() for p in sys.argv[1:]]
ENV={k:v for k,v in os.environ.items() if not k.startswith('BEND_') and k not in ['NODE_OPTIONS','NODE_PATH']}
def ident(p):return {'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
def save(p,x):p.write_text(json.dumps(x,indent=2)+'\n')
def child(args,prefix,timeout):
    command=['taskset','-c','6',str(NODE),'--stack-size=4096','--max-old-space-size=1024',*map(str,args)]
    row={'command':command,'timeoutSeconds':timeout,'complete':False};begin=time.monotonic()
    with prefix.with_suffix('.stdout').open('w') as stdout,prefix.with_suffix('.stderr').open('w') as stderr:
        try:row['exitCode']=subprocess.run(command,cwd=ROOT,env=ENV,stdout=stdout,stderr=stderr,timeout=timeout).returncode
        except subprocess.TimeoutExpired:row['timeout']=True
    row['acquisitionSeconds']=time.monotonic()-begin
    row['scope']='Descriptive acquisition only; not comparative runtime or compiler throughput.'
    row['stdout']=ident(prefix.with_suffix('.stdout'));row['stderr']=ident(prefix.with_suffix('.stderr'))
    text=prefix.with_suffix('.stdout').read_text()
    try:row['result']=json.loads(text)
    except json.JSONDecodeError:pass
    row['complete']=row.get('exitCode')==0 and not row.get('timeout',False)
    save(prefix.with_suffix('.json'),row);return row
def init(out,kind,files):
    out.mkdir(parents=True,exist_ok=False);(out/'tools').mkdir()
    inputs=[ident(p) for p in [Path(__file__),NODE,attempt/'attempt.json',*files]]
    for p in [Path(__file__),*files]:
        if p.suffix in ['.mjs','.py','.json']:(out/'tools'/(p.parent.name+'-'+p.name)).write_bytes(p.read_bytes())
    report={'kind':kind,'complete':False,'attempt':ident(attempt/'attempt.json'),'inputs':inputs}
    save(out/'report.json',report);return report
def close(out,report):
    for p in report['inputs']:assert ident(Path(p['file']))==p,p['file']
    save(out/'report.json',report)

componentSource=HERE.parent/'phase27/component-membership.bend'
emitter=HERE.parent/'phase26/emit.mjs';oracle=HERE.parent/'phase27/component-membership-oracle.mjs'
report=init(componentOut,'phase29-actual-component-acquisition',[componentSource,emitter,oracle])
module=componentOut/'candidate.mjs'
report['emission']=child([emitter,attempt,componentSource,module],componentOut/'emit',120);save(componentOut/'report.json',report)
if report['emission']['complete'] and report['emission']['result'].get('complete'):
    report['check']=child([oracle,module],componentOut/'check',60)
    result=report['check'].get('result',{}).get('results',[])
    report['complete']=report['check']['complete'] and len(result)==1 and result[0]['pass'] and len(result[0]['observations'])==22
    report['module']=ident(module)
close(componentOut,report)
assert report['complete'],'component acquisition failed; retained receipts'

appSource=HERE.parent/'phase28/corpus/app-pure-hvm5-mini.bend'
emitter=HERE.parent/'phase28/emit-program.mjs';oldConfig=ROOT/'selfhost/build/phase28/application-timing-config.json'
config=json.loads(oldConfig.read_text())
report=init(applicationOut,'phase29-HVM-program-acquisition',[appSource,emitter,oldConfig])
program=applicationOut/'candidate.mjs'
report['emission']=child([emitter,'selfhost',attempt,appSource,program],applicationOut/'emit',120);save(applicationOut/'report.json',report)
if report['emission']['complete'] and report['emission']['result'].get('complete'):
    report['execution']=child([program],applicationOut/'run',60)
    stdout=(applicationOut/'run.stdout').read_text();stderr=(applicationOut/'run.stderr').read_text()
    report['expectedStdout']=config['expectedStdout'];report['actualStdout']=stdout
    report['exactStdout']=stdout==config['expectedStdout'];report['emptyStderr']=not stderr
    report['complete']=report['execution']['complete'] and report['exactStdout'] and report['emptyStderr']
    report['program']=ident(program)
close(applicationOut,report)
assert report['complete'],'application acquisition failed; retained receipts'
config['kind']='phase29-three-variant-application-timing-config'
config['variants']['candidate']={'program':ident(program),'original':ident(program),'moduleHost':'ESM'}
config['inputs'] += [ident(oldConfig),ident(applicationOut/'report.json'),ident(program.with_suffix('.mjs.json')),ident(attempt/'attempt.json')]
config['comparisonScope']='Same saved TypeScript/Phase27 programs and checked Phase29 candidate; complete fresh process timing. Requires three-variant runner, not unchanged Phase28 two-variant runner.'
save(applicationOut/'timing-config.json',config)
print(json.dumps({'complete':True,'componentObservations':22,'applicationStdout':report['actualStdout'],'candidate':report['program'],'threeVariantConfig':str(applicationOut/'timing-config.json')}))
