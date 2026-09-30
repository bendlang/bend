#!/usr/bin/env python3
"""Serial paired measurements; never aggregate survivors of a failed case."""
from pathlib import Path
import json,math,statistics,sys,time
HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE.parent/'phase25'))
from campaign import child,ident,save,verify,NODE
configfile,out=map(lambda p:Path(p).resolve(),sys.argv[1:]);config=json.loads(configfile.read_text())
out.mkdir(parents=True,exist_ok=False)
inputs=[ident(p) for p in [configfile,Path(__file__),HERE/'execute.mjs',HERE.parent/'phase25/campaign.py',NODE]]
for c in config['cases']:inputs.extend(ident(p) for p in c['modules'].values())
report={'kind':'phase28-broader-programs','complete':False,'inputs':inputs,'cases':[],
 'scope':'Same checked source/input, CPU3 Node24 stack4MiB heap1GiB;5 fresh processes/output, alternating order; first call separate; then>=3 calls AND1000ms warmup;300ms calibrated target capped1M; exact full result checks inside timing.'}
start=time.monotonic();save(out/'report.json',report)
for c in config['cases']:
    directory=out/c['id'];directory.mkdir();cfg={k:c[k] for k in ['args','expected','exportName']}
    save(directory/'point.json',cfg)
    row={'id':c['id'],'point':cfg,'calibration':{},'checks':{},'samples':[],'complete':False};report['cases'].append(row)
    for side,module in c['modules'].items():
        row['checks'][side]=child([HERE/'execute.mjs','check',module,directory/'point.json'],directory/(side+'-check'),120)
        save(out/'report.json',report)
        if not row['checks'][side]['complete']:break
        cal=child([HERE/'execute.mjs','calibrate',module,directory/'point.json'],directory/(side+'-calibrate'),120)
        row['calibration'][side]=cal;save(out/'report.json',report)
        if not cal['complete']:break
        result=cal['result'];n=max(1,min(1000000,math.ceil(300*result['repetitions']/result['executionMs'])))
        save(directory/(side+'.json'),{**cfg,'repetitions':n})
    if len(row['calibration'])!=2 or not all(x['complete'] for x in row['calibration'].values()):
        row['status']='check-or-calibration-failed';save(out/'report.json',report);continue
    for i in range(5):
        for side in (['upstream','selfhost'] if i%2==0 else ['selfhost','upstream']):
            sample=child([HERE/'execute.mjs','time',c['modules'][side],directory/(side+'.json')],directory/f'{i}-{side}',120)
            sample.update(variant=side,repetition=i);row['samples'].append(sample);save(out/'report.json',report)
    if not all(s['complete'] for s in row['samples']):
        row['status']='sample-failed';save(out/'report.json',report);continue
    row['sides']={}
    for side in ['upstream','selfhost']:
        ss=[s for s in row['samples'] if s['variant']==side];times=[s['result']['executionMs']/s['result']['repetitions'] for s in ss]
        first=[s['result']['firstCallMs'] for s in ss]
        row['sides'][side]={'medianMs':statistics.median(times),'minMs':min(times),'maxMs':max(times),'samplesMs':times,
         'firstCallMedianMs':statistics.median(first),'firstCallSamplesMs':first,
         'peakRssKiB':[s['result']['peakRssKiB'] for s in ss],'importMs':[s['result']['importMs'] for s in ss]}
    row['ratio']=row['sides']['selfhost']['medianMs']/row['sides']['upstream']['medianMs']
    row['firstCallRatio']=row['sides']['selfhost']['firstCallMedianMs']/row['sides']['upstream']['firstCallMedianMs']
    row['complete']=True;row['status']='measured';save(out/'report.json',report)
    print(json.dumps({k:row[k] for k in ['id','ratio','firstCallRatio','sides']}),flush=True)
verify(inputs);report['complete']=True;report['allCasesMeasured']=all(c['complete'] for c in report['cases']);report['wallSeconds']=time.monotonic()-start
save(out/'report.json',report)
