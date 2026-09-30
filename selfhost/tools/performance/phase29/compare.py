#!/usr/bin/env python3
"""Fixed prospective protocols over immutable emitted bytes; no compiler build."""
from pathlib import Path
import json,math,statistics,sys,time
HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE.parent/'phase25'))
from campaign import child,ident,save,verify,NODE

configfile,out=map(lambda p:Path(p).resolve(),sys.argv[1:])
config=json.loads(configfile.read_text())
protocols={'screen':dict(samples=3,warmupCalls=8,warmupMs=100,calibrationMs=50,targetMs=150,timeout=60),
           'confirm':dict(samples=5,warmupCalls=100,warmupMs=3000,calibrationMs=50,targetMs=300,timeout=120),
           'transfer':dict(samples=5,warmupCalls=3,warmupMs=1000,calibrationMs=100,targetMs=300,timeout=120)}
protocol=protocols[config['protocol']]
out.mkdir(parents=True,exist_ok=False)
inputs=[ident(p) for p in [configfile,Path(__file__),HERE/'execute.mjs',HERE.parent/'phase25/campaign.py',NODE]]
inputs+=config.get('inputs',[])
for c in config['cases']:
    assert len(c['modules'])>=2 and all(s.replace('-','').replace('_','').isalnum() for s in c['modules'])
    inputs.extend(ident(p) for p in c['modules'].values())
verify(inputs)
report={'kind':'phase29-paired-generated-execution','complete':False,'inputs':inputs,'protocol':protocol,
 'scope':'Fresh processes in rotating serial CPU3 order; exact result checks inside each call; first call separate; prescribed warmup and timed target. No diagnostics. Config records provenance separately for compiler emissions and disposable prototypes.',
 'cases':[]}
start=time.monotonic();save(out/'report.json',report)
for c in config['cases']:
    directory=out/c['id'];directory.mkdir()
    cfg={**c['point'],**{k:protocol[k] for k in ['warmupCalls','warmupMs','calibrationMs']}}
    cfg.setdefault('exportName','bench');save(directory/'point.json',cfg)
    row={'id':c['id'],'point':cfg,'checks':{},'calibration':{},'samples':[],'complete':False};report['cases'].append(row)
    for side,module in c['modules'].items():
        check=child([HERE/'execute.mjs','check',module,directory/'point.json'],directory/(side+'-check'),protocol['timeout'])
        row['checks'][side]=check;save(out/'report.json',report)
        if not check['complete']:continue
        cal=child([HERE/'execute.mjs','calibrate',module,directory/'point.json'],directory/(side+'-calibrate'),protocol['timeout'])
        row['calibration'][side]=cal;save(out/'report.json',report)
        if not cal['complete']:continue
        result=cal['result'];n=max(1,min(1000000,math.ceil(protocol['targetMs']*result['repetitions']/result['executionMs'])))
        save(directory/(side+'.json'),{**cfg,'repetitions':n})
    if len(row['calibration'])!=len(c['modules']) or not all(v['complete'] for v in row['calibration'].values()):
        row['status']='check-or-calibration-failed';save(out/'report.json',report);continue
    sides=list(c['modules'])
    for index in range(protocol['samples']):
        order=sides[index%len(sides):]+sides[:index%len(sides)]
        for side in order:
            sample=child([HERE/'execute.mjs','time',c['modules'][side],directory/(side+'.json')],directory/f'{index}-{side}',protocol['timeout'])
            sample.update(variant=side,repetition=index);row['samples'].append(sample);save(out/'report.json',report)
    if not all(s['complete'] for s in row['samples']):
        row['status']='sample-failed';save(out/'report.json',report);continue
    row['sides']={}
    for side in sides:
        ss=[s for s in row['samples'] if s['variant']==side]
        times=[s['result']['executionMs']/s['result']['repetitions'] for s in ss]
        first=[s['result']['firstCallMs'] for s in ss]
        row['sides'][side]={'medianMs':statistics.median(times),'minMs':min(times),'maxMs':max(times),'samplesMs':times,
          'firstCallMedianMs':statistics.median(first),'firstCallSamplesMs':first,'peakRssKiB':[s['result']['peakRssKiB'] for s in ss],
          'importMs':[s['result']['importMs'] for s in ss]}
    row.update(complete=True,status='measured');save(out/'report.json',report)
    print(json.dumps({'id':c['id'],'sides':row['sides']}),flush=True)
verify(inputs);report.update(complete=True,allCasesMeasured=all(c['complete'] for c in report['cases']),wallSeconds=time.monotonic()-start)
save(out/'report.json',report)
raise SystemExit(0 if report['allCasesMeasured'] else 1)
