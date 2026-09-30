#!/usr/bin/env python3
"""Keep algorithms, tiny tests, warmup windows and whole processes distinct."""
from pathlib import Path
import hashlib,json,statistics,sys
raw,out=map(lambda p:Path(p).resolve(),sys.argv[1:])
config=json.loads((raw/'timing-config.json').read_text());meta={c['id']:c for c in config['cases']}
result={'complete':False,'units':'milliseconds per complete exported call unless explicitly processMilliseconds',
 'scope':'Generated JavaScript from identical pinned Bend source; no production-average or compiler-throughput inference. Original and follow-up windows are separate.','windows':[]}
for name in ['timing-01','timing-long-01']:
    p=raw/name/'report.json';r=json.loads(p.read_text());assert r['complete']
    window={'name':name,'reportSha256':hashlib.sha256(p.read_bytes()).hexdigest(),'scope':r['scope'],'allCasesMeasured':r['allCasesMeasured'],'wallSeconds':r['wallSeconds'],'cases':[]}
    for c in r['cases']:
        row={'id':c['id'],'category':meta[c['id']]['category'],'inputDescription':meta[c['id']]['inputDescription'],'point':c['point'],'status':c['status']}
        if c['complete']:
            row.update(sides=c['sides'],ratio=c['ratio'],firstCallRatio=c['firstCallRatio'])
            for side in ['upstream','selfhost']:
                ss=[s for s in c['samples'] if s['variant']==side];assert len(ss)==5 and all(s['complete'] for s in ss)
                assert statistics.median(s['result']['executionMs']/s['result']['repetitions'] for s in ss)==c['sides'][side]['medianMs']
                row['sides'][side]['actualWarmupCalls']=[s['result']['warmup'] for s in ss]
                row['sides'][side]['actualWarmupMs']=[s['result']['warmupMs'] for s in ss]
                row['sides'][side]['actualTimedMs']=[s['result']['executionMs'] for s in ss]
                row['sides'][side]['secondOverFirstHalf']=[(s['result']['halves'][1]['ms']/s['result']['halves'][1]['calls'])/(s['result']['halves'][0]['ms']/s['result']['halves'][0]['calls']) if len(s['result']['halves'])==2 else None for s in ss]
        window['cases'].append(row)
    result['windows'].append(window)
p=raw/'application-timing-01/report.json';a=json.loads(p.read_text());assert a['complete']
result['application']={'reportSha256':hashlib.sha256(p.read_bytes()).hexdigest(),'scope':a['timingScope'],'allSamplesValid':a['allSamplesValid'],'summary':a.get('summary'),
 'expectedStdout':a['config']['expectedStdout'],'oracleScope':a['config']['oracleScope']}
result['complete']=True;out.write_text(json.dumps(result,indent=2)+'\n')
