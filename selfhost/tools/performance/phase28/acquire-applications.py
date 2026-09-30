#!/usr/bin/env python3
"""Acquire four exact original mixed tests and the complete HVM application."""
from pathlib import Path
import hashlib,json,subprocess,sys,time
TOOLS=Path(__file__).resolve().parent
ROOT=TOOLS.parents[3]
NODE=Path('/home/ai/.nvm/versions/node/v24.18.0/bin/node')
manifest,attempt,out=[Path(p).resolve() for p in sys.argv[1:]]
out.mkdir(parents=True,exist_ok=False)
def ident(p):
    return {'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
def save(p,v):
    p.write_text(json.dumps(v,indent=2)+'\n')
report={'kind':'phase28-application-acquisition','complete':False,'inputs':[ident(p) for p in [manifest,attempt/'attempt.json',NODE,Path(__file__),TOOLS/'check-application.mjs',TOOLS/'emit-program.mjs',TOOLS.parent/'phase25/emit.mjs',TOOLS.parent/'phase26/emit.mjs']],'cpu':6,'heapMb':1024,'stackKb':4096,'compileTimeoutSeconds':120,'checkTimeoutSeconds':60,'cases':[]}
save(out/'report.json',report)
def child(args,prefix,timeout,json_result=True):
    command=['taskset','-c','6',str(NODE),'--stack-size=4096','--max-old-space-size=1024',*map(str,args)]
    row={'command':command,'timeoutSeconds':timeout,'complete':False};start=time.monotonic()
    stdout=prefix.with_suffix('.stdout');stderr=prefix.with_suffix('.stderr')
    with stdout.open('wb') as sout,stderr.open('wb') as serr:
        try:
            proc=subprocess.run(command,stdout=sout,stderr=serr,timeout=timeout)
            row['returncode']=proc.returncode
        except subprocess.TimeoutExpired:row['timeout']=True
    row['elapsedSeconds']=time.monotonic()-start
    row['timingScope']='Descriptive acquisition only; concurrent acquisition may run on another CPU.'
    if json_result:
        lines=stdout.read_text().splitlines()
        if lines:
            try:
                row['result']=json.loads(lines[-1]);row['complete']=row.get('returncode')==0 and row['result'].get('complete',False)
            except json.JSONDecodeError:pass
    else:
        row['complete']=row.get('returncode')==0
        row['output']=stdout.read_text()
    row['stdout']=ident(stdout);row['stderr']=ident(stderr);save(prefix.with_suffix('.json'),row)
    return row
for case in json.loads(manifest.read_text())['cases']:
    source=ROOT/case['source'];assert ident(source)['sha256']==case['origin']['sha256']
    report['inputs'].append(ident(source));directory=out/case['id'];directory.mkdir()
    row={'id':case['id'],'case':case,'source':ident(source),'variants':{}};report['cases'].append(row)
    save(directory/'point.json',case)
    for side in ['upstream','selfhost']:
        module=directory/(side+'.mjs')
        if case['mode']=='program':args=[TOOLS/'emit-program.mjs',side,attempt,source,module]
        elif side=='upstream':args=[TOOLS.parent/'phase25/emit.mjs',side,source,module]
        else:args=[TOOLS.parent/'phase26/emit.mjs',attempt,source,module]
        variant={'emission':child(args,directory/(side+'-emit'),120)};row['variants'][side]=variant;save(out/'report.json',report)
        if variant['emission']['complete']:
            run_args=[module] if case['mode']=='program' else [TOOLS/'check-application.mjs',module,directory/'point.json']
            variant['execution']=child(run_args,directory/(side+'-check'),60,case['mode']!='program')
        save(out/'report.json',report)
        print(json.dumps({'case':case['id'],'side':side,'emitted':variant['emission']['complete'],'checked':variant.get('execution',{}).get('complete',False),'emissionSeconds':variant['emission']['elapsedSeconds'],'firstCallMs':variant.get('execution',{}).get('result',{}).get('firstCallMs'),'processSeconds':variant.get('execution',{}).get('elapsedSeconds')}),flush=True)
    if case['mode']=='program':
        executions=[row['variants'][s].get('execution',{}) for s in ['upstream','selfhost']]
        row['exactStdoutAgreement']=all(e.get('complete',False) for e in executions) and executions[0]['output']==executions[1]['output']
        row['oracleScope']='Complete differential stdout; no independent interaction-count golden.'
        save(out/'report.json',report)
for entry in report['inputs']:assert ident(Path(entry['file']))['sha256']==entry['sha256'],entry['file']
report['complete']=True
report['allEmittedAndChecked']=all(v['emission']['complete'] and v.get('execution',{}).get('complete',False) for c in report['cases'] for v in c['variants'].values()) and all(c.get('exactStdoutAgreement',True) for c in report['cases'])
save(out/'report.json',report)
