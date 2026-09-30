#!/usr/bin/env python3
"""Replay selected emitted artifacts under diagnostics after clean timing ends."""
from pathlib import Path
import json, math, subprocess, sys
from campaign import ROOT, SH, TOOLS, NODE, ENV, FLAGS, ident, save, verify

corpus,timing,out=[Path(p).resolve() for p in sys.argv[1:]]
out.mkdir(parents=True,exist_ok=False)
(out/'consumed-launcher.py').write_bytes(Path(__file__).read_bytes())
m=json.loads((corpus/'manifest.json').read_text()); t=json.loads((timing/'report.json').read_text())
assert m['complete'] and t['complete'];verify(m['inputs'])
# Largest known structural differences plus ordinary kernels and a near-parity
# counterexample. Selection is for explanation, not a new aggregate speed score.
selected=['scalar-arithmetic','boolean-choice','boolean-worker','match-remaining-args',
          'string-scan','string-equality','term-substitution','pinned-u32-table','pinned-u32-wide']
plan={'kind':'phase25-diagnostic-plan','corpus':ident(corpus/'manifest.json'),'timing':ident(timing/'report.json'),'tool':ident(TOOLS/'diagnostics.mjs'),'launcher':ident(__file__),'selected':selected,'rows':[],
      'policy':'Separate from clean timing. Largest input of each selected family. CPU/allocation target about500ms uninstrumented work per output, capped1M calls. Counters10calls. Warmup at least measured median warmup calls. No diagnostic duration is a benchmark sample.'}
for name in selected:
    row=next(x for x in reversed(t['summary']) if x['id']==name)
    for side in ['upstream','selfhost']:
        samples=[x for x in t['samples'] if x['key']==row['key'] and x['variant']==side]
        config={'module':str(corpus/name/(side+'.mjs')),'size':row['config']['size'],'seed':row['config']['seed'],
                'expectedResult':row['config']['expected'],'repetitions':max(1,min(1000000,math.ceil(500/row['sides'][side]['medianMsPerCall']))),
                'warmup':sorted(x['result']['warmup'] for x in samples)[len(samples)//2],
                'counterRepetitions':10,'sampleIntervalBytes':262144,'samplingIntervalUs':1000}
        plan['rows'].append({'name':name,'side':side,'config':config})
save(out/'plan.json',plan)
code="import fs from 'node:fs';import {pathToFileURL} from 'node:url';const {runDiagnostic}=await import(pathToFileURL(process.argv[2]));await runDiagnostic(JSON.parse(fs.readFileSync(process.argv[3])),process.argv[4]);"
results=[]
for row in plan['rows']:
    destination=out/(row['name']+'-'+row['side']);config=out/(row['name']+'-'+row['side']+'.json');save(config,row['config'])
    command=['taskset','-c','3',str(NODE),*FLAGS,'--input-type=module','-e',code,'phase25-diagnostic-launcher',str(TOOLS/'diagnostics.mjs'),str(config),str(destination)]
    result={'name':row['name'],'side':row['side'],'command':command,'timeoutSeconds':15}
    try:
        with (out/(destination.name+'.stdout')).open('w') as a,(out/(destination.name+'.stderr')).open('w') as b:
            p=subprocess.run(command,cwd=SH,env=ENV,stdout=a,stderr=b,timeout=15)
        result['exitCode']=p.returncode
        if (destination/'report.json').exists():result['report']=ident(destination/'report.json');result['status']=json.loads((destination/'report.json').read_text())['status']
    except Exception as e:result['error']=str(e)
    results.append(result);save(out/'results.json',results);print(json.dumps({k:v for k,v in result.items() if k!='command'}),flush=True)
verify(m['inputs']);assert all(x.get('status')=='pass' and x.get('exitCode')==0 for x in results)
