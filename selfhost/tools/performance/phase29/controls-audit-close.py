#!/usr/bin/env python3
"""Combine independent Phase29 receipts and audit cross-scope serialization."""
from pathlib import Path
import hashlib,json,sys
raw,out=map(lambda x:Path(x).resolve(),sys.argv[1:]);assert not out.exists()
checks=0;hashed={}
def require(test,label):
    global checks
    checks+=1
    if not test:raise AssertionError(label)
def identity(p):
    p=Path(p);hashed[str(p)]=hashlib.sha256(p.read_bytes()).hexdigest()
    return {'file':str(p),'sha256':hashed[str(p)]}
def verify(x):require(identity(x['file'])['sha256']==x['sha256'],x['file']+' hash')
def read(p):return json.loads(Path(p).read_text())
result={'kind':'phase29-independent-combined-measurement-audit','complete':False,'pass':False,'tool':identity(__file__)}
try:
    lf=raw/'controls-measurement-audit-final-04.json';af=raw/'controls-application-audit-final-04.json'
    library=read(lf);application=read(af)
    for audit in [library,application]:
        require(audit['complete'] and audit['pass'],'independent scope passed');verify(audit['tool'])
    names=['prototype-screen-01','prototype-confirm-01','arithmetic-transfer-01','fixture-screen-04','fixture-confirm-04','transfer-timing-04','transfer-confirm-04','components-confirm-04','evening-confirm-04']
    require([Path(c['report']['file']).parent.name for c in library['campaigns']]==names,'all nine library windows retained')
    intervals=[];reports={}
    for campaign in library['campaigns']:
        verify(campaign['report']);report=read(campaign['report']['file']);reports[Path(campaign['report']['file']).parent.name]=report
        for case in report['cases']:
            rows=list(case['checks'].values())+list(case['calibration'].values())+case['samples']
            for row in rows:intervals.append((row['started'],row['started']+row['processSeconds']))
    verify(application['report']);ar=read(application['report']['file'])
    intervals.extend((r['started'],r['finished']) for r in ar['samples']);intervals.sort()
    for a,b in zip(intervals,intervals[1:]):require(a[1]<=b[0]+0.002,'recorded library/application children do not overlap')
    processes=sum(c['processes']for c in library['campaigns']);timed=sum(c['timedSamples']for c in library['campaigns'])
    require((processes,timed,application['processes'],len(intervals))==(586,414,15,601),'exact full inventory')
    original=next(c for c in reports['transfer-timing-04']['cases']if c['id']=='test-evening-program');follow=reports['evening-confirm-04']['cases'][0]
    require(all(original['point'][k]==follow['point'][k]for k in ['args','expected','exportName']),'evening identical input, export and oracle; warmup protocol intentionally changes')
    for side in ['upstream','old','candidate']:
        require(original['checks'][side]['result']['module']==follow['checks'][side]['result']['module'],'evening identical '+side+' module bytes')
    launch=read(raw/'final-campaigns.json');evening=read(raw/'evening-confirm-launcher.json')
    require(launch['complete'] and all(r['complete'] and r['returncode']==0 for r in launch['runs']),'planned launch completion')
    require(evening['complete'] and evening['returncode']==0,'follow-up launch completion')
    require(launch['runs'][-1]['started']+launch['runs'][-1]['wallSeconds']<=evening['started'],'follow-up after planned campaigns')
    result.update(library={'receipt':identity(lf),'campaigns':9,'processes':processes,'timedSamples':timed,'checks':library['checks'],'distinctHashedFiles':library['distinctHashedFiles']},application={'receipt':identity(af),'campaigns':1,'processes':15,'timedSamples':15,'checks':application['checks'],'distinctHashedFiles':application['distinctHashedFiles']},totalProcesses=len(intervals),totalTimedObservations=timed+15,campaigns=library['campaigns'],warnings=library['warnings'],applicationSummary=application['sides'],launchers=[identity(raw/'final-campaigns.json'),identity(raw/'evening-confirm-launcher.json')])
    result['retainedFailures']=[identity(raw/p)for p in ['attempt-02/build.json','transfer-03/symreg/emission/launch.json','transfer-03/raytrace/emission/launch.json','controls-worker-frontier-old-03/report.json']]
    result['interpretation']={'scope':'Generated JavaScript execution, not compiler throughput. Timed observations have different library and whole-process scopes.','drift':'Retain every window. Sorting/map-set remain sensitive after confirmation; one-call samples have no half estimate.','evening':'Original-window regression and longer-warm improvement both retained; no specific JIT cause established.','application':'HVM median slightly slower with overlapping ranges; no speedup claim.','auditCounts':'Assertion counts and file counts are audit scopes, not unique conformance checks. File sets overlap between audits.'}
    result.update({'complete':True,'pass':True})
except Exception as error:result['error']=repr(error)
result['crossScopeChecks']=checks;result['crossScopeDistinctHashedFiles']=len(hashed)
out.write_text(json.dumps(result,indent=2)+'\n');print(json.dumps({k:result[k]for k in ['complete','pass','crossScopeChecks']}));sys.exit(0 if result['pass']else 1)
