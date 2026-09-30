#!/usr/bin/env python3
"""Acquire all six frozen runtime fixtures; failures stay in the report."""
from pathlib import Path
import hashlib,json,subprocess,sys,time
TOOLS=Path(__file__).resolve().parent
ROOT=TOOLS.parents[3]
NODE=Path('/home/ai/.nvm/versions/node/v24.18.0/bin/node')
manifest,attempt,out=[Path(p).resolve() for p in sys.argv[1:]]
out.mkdir(parents=True,exist_ok=False)
def ident(p):
    return {'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
def save(p,data):
    p.write_text(json.dumps(data,indent=2)+'\n')
report={'kind':'phase28-six-runtime-acquisition','complete':False,'inputs':[ident(manifest),ident(attempt/'attempt.json'),ident(NODE),ident(Path(__file__)),ident(TOOLS/'check-once.mjs'),ident(TOOLS.parent/'phase25/emit.mjs'),ident(TOOLS.parent/'phase26/emit.mjs')],'cpu':4,'heapMb':1024,'stackKb':4096,'compileTimeoutSeconds':120,'checkTimeoutSeconds':60,'cases':[]}
save(out/'report.json',report)
def child(args,prefix,timeout):
    cmd=['taskset','-c','4',str(NODE),'--stack-size=4096','--max-old-space-size=1024',*map(str,args)]
    row={'command':cmd,'timeoutSeconds':timeout,'complete':False};start=time.monotonic()
    with prefix.with_suffix('.stdout').open('w') as stdout,prefix.with_suffix('.stderr').open('w') as stderr:
        try:
            proc=subprocess.run(cmd,stdout=stdout,stderr=stderr,timeout=timeout)
            row['returncode']=proc.returncode
        except subprocess.TimeoutExpired:
            row['timeout']=True
    row['elapsedSeconds']=time.monotonic()-start
    row['timingScope']='Descriptive acquisition process wall time only; not controlled compiler throughput or runtime performance.'
    lines=prefix.with_suffix('.stdout').read_text().splitlines()
    if lines:
        try:row['result']=json.loads(lines[-1]);row['complete']=row.get('returncode')==0 and row['result'].get('complete',False)
        except json.JSONDecodeError:pass
    row['stdout']=ident(prefix.with_suffix('.stdout'));row['stderr']=ident(prefix.with_suffix('.stderr'))
    save(prefix.with_suffix('.json'),row)
    return row
for case in json.loads(manifest.read_text())['cases']:
    source=ROOT/case['fixture']['path'];assert ident(source)['sha256']==case['fixture']['sha256']
    report['inputs'].append(ident(source));directory=out/case['id'];directory.mkdir()
    row={'id':case['id'],'source':ident(source),'point':case['point'],'variants':{}};report['cases'].append(row)
    save(directory/'point.json',case['point'])
    for side in ['upstream','selfhost']:
        module=directory/(side+'.mjs')
        args=[TOOLS.parent/'phase25/emit.mjs','upstream',source,module] if side=='upstream' else [TOOLS.parent/'phase26/emit.mjs',attempt,source,module]
        variant={'emission':child(args,directory/(side+'-emit'),120)};row['variants'][side]=variant
        save(out/'report.json',report)
        if variant['emission']['complete']:
            variant['execution']=child([TOOLS/'check-once.mjs',module,directory/'point.json'],directory/(side+'-check'),60)
        save(out/'report.json',report)
        print(json.dumps({'case':case['id'],'side':side,'emitted':variant['emission']['complete'],'checked':variant.get('execution',{}).get('complete',False),'emissionSeconds':variant['emission']['elapsedSeconds'],'firstCallMs':variant.get('execution',{}).get('result',{}).get('firstCallMs')}),flush=True)
for entry in report['inputs']:
    assert ident(Path(entry['file']))['sha256']==entry['sha256'],entry['file']
report['complete']=True
report['allEmittedAndChecked']=all(v['emission']['complete'] and v.get('execution',{}).get('complete',False) for c in report['cases'] for v in c['variants'].values())
save(out/'report.json',report)
