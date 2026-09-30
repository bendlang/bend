#!/usr/bin/env python3
"""Small diagnostic trace acquisition; no timings are used for comparison."""
from pathlib import Path
import json, subprocess, sys, collections
from campaign import SH, TOOLS, NODE, FLAGS, ENV, ident, save

def parse_observation(text):
    # V8 may print another asynchronous GC/optimization line after our JSON.
    rows=[json.loads(line) for line in text.splitlines() if line.startswith('{"kind":"phase25-v8-diagnostic-trace"')]
    assert len(rows)==1
    return rows[0]

if sys.argv[1]=='--summarize':
    source,out=map(lambda p:Path(p).resolve(),sys.argv[2:])
    old=json.loads((source/'report.json').read_text());rows=[]
    for row in old:
        stem=row['name']+'-'+row['side'];file=source/(stem+'.stdout')
        observation=parse_observation(file.read_text());assert row['exitCode']==0 and observation['complete']
        rows.append({**row,'complete':True,'originalSummaryComplete':row['complete'],'originalParserError':row.get('error'),'error':None,'observation':observation,'stdout':ident(file)})
    save(out,{'complete':True,'scope':'Reconciled unchanged successful trace processes; initial parser wrongly assumed its JSON was the last stdout line. Original report/failures retained. These are diagnostics, not comparative times.','originalReport':ident(source/'report.json'),'parser':ident(__file__),'rows':rows})
    sys.exit(0)
diagnostics,out=[Path(p).resolve() for p in sys.argv[1:]]
out.mkdir(parents=True,exist_ok=False)
(out/'consumed-launcher.py').write_bytes(Path(__file__).read_bytes())
plan=json.loads((diagnostics/'plan.json').read_text());results=[]
for row in plan['rows']:
    if row['name'] not in ['scalar-arithmetic','pinned-u32-table','pinned-u32-wide','string-equality']:continue
    stem=row['name']+'-'+row['side'];config=out/(stem+'.json');save(config,row['config'])
    command=['taskset','-c','3',str(NODE),*FLAGS,'--trace-opt','--trace-deopt','--trace-gc',str(TOOLS/'trace.mjs'),str(config)]
    observation={'name':row['name'],'side':row['side'],'command':command,'tool':ident(TOOLS/'trace.mjs'),'module':ident(row['config']['module']),'timeoutSeconds':15}
    try:
        with (out/(stem+'.stdout')).open('w') as a,(out/(stem+'.stderr')).open('w') as b:
            p=subprocess.run(command,cwd=SH,env=ENV,stdout=a,stderr=b,timeout=15)
        observation['exitCode']=p.returncode
        text=(out/(stem+'.stdout')).read_text();steady=text.split('PHASE25_BEGIN_STEADY\n')[1].split('PHASE25_END_STEADY\n')[0]
        observation['steady']={'gcLines':[x for x in steady.splitlines() if 'Scavenge' in x or 'Mark-Compact' in x],
                               'deoptimizationLines':[x for x in steady.splitlines() if 'bailout' in x],
                               'optimizationLines':[x for x in steady.splitlines() if 'optimizing' in x or 'compilation' in x]}
        observation['gcEvents']=len(observation['steady']['gcLines']);observation['deoptimizations']=len(observation['steady']['deoptimizationLines'])
        observation['observation']=parse_observation(text);assert p.returncode==0 and observation['observation']['complete']
        observation['complete']=True
    except Exception as e:observation['complete']=False;observation['error']=str(e)
    results.append(observation);save(out/'report.json',results)
    print(json.dumps({k:observation.get(k) for k in ['name','side','complete','gcEvents','deoptimizations','error']}),flush=True)
assert all(x['complete'] for x in results)
