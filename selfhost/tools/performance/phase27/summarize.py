#!/usr/bin/env python3
"""Summarize every completed window without pooling protocols or variants."""
from pathlib import Path
import hashlib,json,statistics,sys
raw,out=map(Path,sys.argv[1:]);windows=[]
for name in ['timing-01','timing-warm-01','timing-02','timing-warm-02']:
    p=raw/name/'report.json';r=json.loads(p.read_text());assert r['complete']
    w={'name':name,'reportSha256':hashlib.sha256(p.read_bytes()).hexdigest(),'scope':r['scope'],'wallSeconds':r['wallSeconds'],'cases':[]}
    durations=[]
    for c in r['cases']:
        row={'id':c['id'],'point':c['point'],'variants':{}}
        for v in ['upstream','old','candidate']:
            samples=[s for s in c['samples'] if s['variant']==v];assert len(samples)==5 and all(s['complete'] for s in samples)
            times=[s['result']['executionMs']*1000/s['result']['repetitions'] for s in samples]
            durations.extend(s['result']['executionMs'] for s in samples)
            median=statistics.median(times);assert median==c['medianUsPerCall'][v]
            row['variants'][v]={'medianUs':median,'minUs':min(times),'maxUs':max(times),'samplesUs':times}
        row['speedup']=c['speedup'];row['remainingRatio']=c['remainingRatio'];w['cases'].append(row)
    w['samples']=len(durations);w['timedBlockMs']={'min':min(durations),'max':max(durations)};windows.append(w)
out.write_text(json.dumps({'complete':True,'scope':'Generated-program execution, separate clean windows; no compiler throughput or new H claim. Candidate in01 is inline; in02 shared. All samples retained.','windows':windows},indent=2)+'\n')
