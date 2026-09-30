#!/usr/bin/env python3
"""Audit the separate whole-process HVM comparison without executing programs."""
from pathlib import Path
import hashlib,json,statistics,sys
source,out=map(lambda p:Path(p).resolve(),sys.argv[1:]);assert not out.exists()
checks=0;hashes={}
def require(test,label):
    global checks
    checks+=1
    if not test:raise AssertionError(label)
def identity(file):
    p=Path(file)
    if str(p) not in hashes:hashes[str(p)]=hashlib.sha256(p.read_bytes()).hexdigest()
    return {'file':str(p),'sha256':hashes[str(p)]}
def verify(item):require(identity(item['file'])['sha256']==item['sha256'],str(item['file'])+' hash')
audit={'kind':'phase29-independent-application-audit','complete':False,'pass':False,'tool':identity(Path(__file__).resolve()),'report':identity(source),'scope':'All whole-process samples and byte-exact stdout; separate from warmed library execution.'}
try:
  report=json.loads(source.read_text());cfg=report['config'];sides=list(cfg['variants'])
  require(report['kind']=='phase29-application-process-timing','report kind')
  require(report['complete'] and report['allSamplesValid'],'every sample valid, independent of launcher exit status')
  require(set(sides)=={'upstream','selfhost','candidate'},'three variants')
  require(cfg['samplesPerVariant']==5 and len(report['samples'])==15,'all five samples per variant')
  require(cfg['cpu']==3 and cfg['stackKb']==4096 and cfg['heapMb']==1024 and cfg['timeoutSeconds']==120,'fixed resources')
  for item in report['inputs']:verify(item)
  expected=[]
  for index in range(5):expected.extend((index,side)for side in sides[index%3:]+sides[:index%3])
  require([(r['sample'],r['side'])for r in report['samples']]==expected,'rotating serial order')
  intervals=[]
  for row in report['samples']:
    require(row['complete'] and row['returncode']==0 and not row.get('timeout',False),'successful process')
    require(row['command']==['taskset','-c','3',cfg['node'],'--stack-size=4096','--max-old-space-size=1024',cfg['variants'][row['side']]['program']['file']],'exact process command')
    require(row['timeoutSeconds']==120 and row['elapsedSeconds']>0,'deadline and wall time')
    require(row['exactStdout'] and row['emptyStderr'],'complete stdout/stderr checks')
    verify(row['stdout']);verify(row['stderr'])
    require(Path(row['stdout']['file']).read_bytes()==cfg['expectedStdout'].encode(),'exact full stdout bytes')
    require(Path(row['stderr']['file']).read_bytes()==b'','empty stderr bytes')
    raw=json.loads((source.parent/f"{row['sample']:02d}-{row['side']}.json").read_text())
    require(raw==row,'raw sample equals aggregate')
    require(abs((row['finished']-row['started'])-row['elapsedSeconds'])<0.02,'wall interval agrees with monotonic timing')
    intervals.append((row['started'],row['finished']))
  for a,b in zip(intervals,intervals[1:]):require(a[1]<=b[0],'whole-process samples do not overlap')
  audit['sides']={}
  for side in sides:
    values=[r['elapsedSeconds']for r in report['samples']if r['side']==side]
    expected={'samples':5,'medianSeconds':statistics.median(values),'minSeconds':min(values),'maxSeconds':max(values)}
    require(report['summary'][side]==expected,'all samples and recomputed '+side+' median/range')
    audit['sides'][side]={**expected,'samplesSeconds':values}
  med=lambda side:audit['sides'][side]['medianSeconds']
  require(report['summary']['selfhostOverUpstream']==med('selfhost')/med('upstream'),'old ratio')
  audit['oldOverUpstream']=med('selfhost')/med('upstream');audit['candidateOverUpstream']=med('candidate')/med('upstream');audit['oldOverCandidate']=med('selfhost')/med('candidate')
  receipt_file=source.parent.with_name(source.parent.name+'-derivation')/'receipt.json';receipt=json.loads(receipt_file.read_text())
  for item in receipt['inputs']:verify(item)
  verify(receipt['derived']);original=Path(receipt['inputs'][1]['file']).read_text()
  for old,new in receipt['changes']:
    require(original.count(old)==1,'unique intended derivation anchor');original=original.replace(old,new)
  require(original==Path(receipt['derived']['file']).read_text(),'derived runner exact replay')
  audit['derivation']=identity(receipt_file);audit['processes']=len(report['samples']);audit['interval']={'firstStarted':intervals[0][0],'lastFinished':intervals[-1][1]};audit['complete']=True;audit['pass']=True
except Exception as error:audit['error']=repr(error)
audit['checks']=checks;audit['distinctHashedFiles']=len(hashes)
out.write_text(json.dumps(audit,indent=2)+'\n');print(json.dumps({'complete':audit['complete'],'pass':audit['pass'],'checks':checks,'error':audit.get('error')}));sys.exit(0 if audit['pass']else 1)
