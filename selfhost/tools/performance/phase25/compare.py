#!/usr/bin/env python3
"""Fast paired probe for two already emitted bench libraries; no compiler build."""
from pathlib import Path
import json, math, statistics, sys, time
from campaign import TOOLS, NODE, child, ident, save, verify

a,b,configfile,out=[Path(p).resolve() for p in sys.argv[1:]]
out.mkdir(parents=True,exist_ok=False)
config=json.loads(configfile.read_text())
assert all(k in config for k in ['size','seed','expected'])
inputs=[ident(p) for p in [a,b,configfile,Path(__file__),TOOLS/'execute.mjs',TOOLS/'campaign.py',NODE]]
report={'kind':'phase25-focused-emitted-comparison','complete':False,'inputs':inputs,'config':config,'calibration':{},'samples':[],
        'scope':'Already emitted modules supplied by caller; this probe does not check source or compiler lineage. Exact scalar oracle, warmed public calls, five fresh processes per output, alternating order. Repetitions differ by output; compare time per call.'}
save(out/'report.json',report);begin=time.monotonic()
save(out/'check-config.json',{'exportName':config.get('exportName','bench'),'inputs':[{'size':config['size'],'seed':config['seed'],'expected':config['expected']}]})
for side,module in [('upstream',a),('selfhost',b)]:
    checked=child([TOOLS/'execute.mjs','check',module,out/'check-config.json'],out/(side+'-check'))
    assert checked['complete'],f'{side} failed exact output gate; original logs retained'
    calibrated=child([TOOLS/'execute.mjs','calibrate',module,configfile],out/(side+'-calibration'))
    report['calibration'][side]=calibrated;save(out/'report.json',report)
    assert calibrated['complete'],f'{side} calibration failed'
    result=calibrated['result'];repetitions=max(1,min(1000000,math.ceil(150/(result['executionMs']/result['repetitions']))))
    save(out/(side+'-config.json'),{**config,'repetitions':repetitions})
for i in range(5):
    for side,module in ([('upstream',a),('selfhost',b)] if i%2==0 else [('selfhost',b),('upstream',a)]):
        row=child([TOOLS/'execute.mjs','time',module,out/(side+'-config.json')],out/f'{i}-{side}')
        row.update(variant=side,repetition=i);report['samples'].append(row);save(out/'report.json',report)
        assert row['complete'],f'{side} sample failed; no survivor-only aggregate'
verify(inputs)
report['medianMsPerCall']={side:statistics.median(row['result']['executionMs']/row['result']['repetitions'] for row in report['samples'] if row['variant']==side) for side in ['upstream','selfhost']}
report['selfhostOverUpstream']=report['medianMsPerCall']['selfhost']/report['medianMsPerCall']['upstream']
report['wallSeconds']=time.monotonic()-begin;report['complete']=True;save(out/'report.json',report)
print(json.dumps({k:report[k] for k in ['complete','medianMsPerCall','selfhostOverUpstream','wallSeconds']}))
