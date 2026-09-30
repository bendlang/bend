#!/usr/bin/env python3
"""Assemble closed raw observations without rerunning programs or hiding drift."""
from pathlib import Path
import hashlib,json,re
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
RAW=ROOT/'selfhost/build/phase29';OUT=ROOT/'implementation/phase29'
names=['prototype-screen-01','prototype-confirm-01','arithmetic-transfer-01',
 'fixture-screen-04','fixture-confirm-04','transfer-timing-04','transfer-confirm-04','components-confirm-04','evening-confirm-04']
def ident(p):return {'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
result={'complete':False,'units':'milliseconds per exported call unless explicitly whole-process',
 'scope':'Within-window medians only; scopes and warmup windows remain separate. Five samples are not confidence bounds or a production average.','windows':[]}
for name in names:
 p=RAW/name/'report.json';r=json.loads(p.read_text());assert r['complete'] and r['allCasesMeasured'],name
 w={'name':name,'report':ident(p),'wallSeconds':r['wallSeconds'],'protocol':r['protocol'],'cases':[]}
 for case in r['cases']:
  sides={key:dict(value) for key,value in case['sides'].items()}
  for key,side in sides.items():
   samples=[s['result'] for s in case['samples'] if s['variant']==key]
   ratios=[]
   for s in samples:
    if len(s['halves'])!=2:ratios.append(None);continue
    a,b=s['halves'];ratios.append((b['ms']/b['calls'])/(a['ms']/a['calls']) if a['calls'] and b['calls'] and a['ms'] else None)
   side.update(secondOverFirstHalf=ratios,actualWarmupCalls=[s['warmup'] for s in samples],
     actualWarmupMs=[s['warmupMs'] for s in samples],actualTimedMs=[s['executionMs'] for s in samples])
  row={'id':case['id'],'point':case['point'],'sides':sides}
  if 'candidate' in sides and 'old' in sides:
   row['oldOverCandidate']=sides['old']['medianMs']/sides['candidate']['medianMs']
   row['firstCallOldOverCandidate']=sides['old']['firstCallMedianMs']/sides['candidate']['firstCallMedianMs']
  if 'upstream' in sides:
   row['overTypeScript']={s:v['medianMs']/sides['upstream']['medianMs'] for s,v in sides.items() if s!='upstream'}
  w['cases'].append(row)
 result['windows'].append(w)
p=RAW/'application-timing-04/report.json';app=json.loads(p.read_text());assert app['complete'] and app['allSamplesValid']
result['wholeProcess']={'report':ident(p),'summary':app['summary'],'scope':app['timingScope']}
files=json.loads((ROOT/'selfhost/src/compiler.json').read_text())['modules']
texts=[(ROOT/'selfhost'/p).read_text() for p in files];lines=[line for t in texts for line in t.splitlines()]
result['source']={'modules':len(files),'physicalLines':len(lines),'nonblankLines':sum(bool(l.strip()) for l in lines),
 'bytes':sum(len(t.encode()) for t in texts),'defs':sum(bool(re.match(r'^def\s',l)) for l in lines),
 'laws':sum(bool(re.match(r'^law\s',l)) for l in lines),'types':sum(bool(re.match(r'^type\s',l)) for l in lines)}
result['shape']=[]
for c in json.loads((RAW/'transfer-04/report.json').read_text())['cases']:
 text=Path(c['modules']['candidate']).read_text()
 result['shape'].append({'id':c['id'],'primitiveSites':text.count('/* primitive */'),'privateLoops':text.count('/* private Nat loop */'),'bytes':len(text.encode())})
result['complete']=True
(OUT/'results.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps({'complete':True,'source':result['source'],'windows':len(result['windows'])}))
