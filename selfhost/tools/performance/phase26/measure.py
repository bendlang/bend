#!/usr/bin/env python3
"""Rotate three frozen emitted outputs; compilation is outside timing."""
from pathlib import Path
import json, math, statistics, sys, time
TOOLS=Path(__file__).resolve().parent
sys.path.insert(0,str(TOOLS.parent/'phase25'))
from campaign import child, ident, save, verify, NODE

configfile,out=[Path(p).resolve() for p in sys.argv[1:]]
config=json.loads(configfile.read_text());out.mkdir(parents=True,exist_ok=False)
inputs=[ident(configfile),ident(Path(__file__)),ident(TOOLS.parent/'phase25/execute.mjs'),ident(TOOLS.parent/'phase25/campaign.py'),ident(NODE)]
for case in config['cases']:
    inputs.extend(ident(p) for p in case['modules'].values())
report={'kind':'phase26-three-output-runtime','complete':False,'inputs':inputs,'cases':[],
        'scope':'Checked frozen emissions supplied by caller; serial CPU3, fresh Node24 process per sample, >=100ms/eight calls warmup, side-specific 150ms calibration capped 1M calls, rotating variant order; includes identical result checks.'}
save(out/'report.json',report);start=time.monotonic()
for case in config['cases']:
    directory=out/case['id'];directory.mkdir()
    row={'id':case['id'],'point':case['point'],'calibration':{},'samples':[]};report['cases'].append(row)
    save(directory/'point.json',case['point'])
    save(directory/'check.json',{'inputs':[case['point']]})
    variants=list(case['modules']);assert variants==['upstream','old','candidate']
    for side,module in case['modules'].items():
        checked=child([TOOLS.parent/'phase25/execute.mjs','check',module,directory/'check.json'],directory/(side+'-check'))
        assert checked['complete'],(case['id'],side,checked)
        cal=child([TOOLS.parent/'phase25/execute.mjs','calibrate',module,directory/'point.json'],directory/(side+'-calibrate'))
        row['calibration'][side]=cal;save(out/'report.json',report)
        assert cal['complete'],(case['id'],side,cal)
        result=cal['result'];n=max(1,min(1000000,math.ceil(150*result['repetitions']/result['executionMs'])))
        save(directory/(side+'.json'),{**case['point'],'repetitions':n})
    for i in range(5):
        order=variants[i%3:]+variants[:i%3]
        if i%2:order=list(reversed(order))
        for side in order:
            sample=child([TOOLS.parent/'phase25/execute.mjs','time',case['modules'][side],directory/(side+'.json')],directory/f'{i}-{side}')
            sample.update(variant=side,repetition=i);row['samples'].append(sample);save(out/'report.json',report)
            assert sample['complete'],(case['id'],side,sample)
    row['medianUsPerCall']={side:statistics.median(s['result']['executionMs']*1000/s['result']['repetitions'] for s in row['samples'] if s['variant']==side) for side in variants}
    med=row['medianUsPerCall'];row['speedup']=med['old']/med['candidate'];row['remainingRatio']=med['candidate']/med['upstream']
    save(out/'report.json',report);print(json.dumps({k:row[k] for k in ['id','medianUsPerCall','speedup','remainingRatio']}),flush=True)
verify(inputs);report['complete']=True;report['wallSeconds']=time.monotonic()-start
save(out/'report.json',report)
