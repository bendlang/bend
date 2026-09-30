#!/usr/bin/env python3
"""Expected-stop tests of the exact supervisor, for an idle serialized slot."""
from pathlib import Path
import fcntl,hashlib,json,os,signal,subprocess,sys,time
root=Path(__file__).resolve().parents[4]
out=Path(sys.argv[1]).resolve();out.mkdir(parents=True,exist_ok=False)
wrapper=root/'selfhost/tools/performance/phase32/bounded-run.py'
child=Path(__file__).with_name('review-supervisor-child.py')
def ident(p):
 p=Path(p);b=p.read_bytes();return {'file':str(p.resolve()),'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest()}
def state(pid):
 try:
  raw=Path(f'/proc/{pid}/stat').read_text();xs=raw[raw.rfind(')')+2:].split();return {'state':xs[0],'startTicks':xs[19]}
 except (FileNotFoundError,ProcessLookupError):return None
def cleanup(receipt):
 if not receipt.exists():return
 d=json.loads(receipt.read_text());s=state(d['pid'])
 if s is None or s['startTicks']!=d['startTicks']:return
 try:os.killpg(d['pid'],signal.SIGKILL)
 except (ProcessLookupError,PermissionError):pass
 try:os.kill(d['pid'],signal.SIGKILL)
 except ProcessLookupError:pass
report={'kind':'phase32-independent-supervisor-expected-stops','complete':False,'pass':False,'scope':'Direct child RSS-limit and deadline controls; not a universal descendant-escape or OOM-prevention proof.','inputs':[ident(__file__),ident(wrapper),ident(child)],'cases':[]}
(out/'consumed-controls.py').write_bytes(Path(__file__).read_bytes());(out/'consumed-child.py').write_bytes(child.read_bytes())
def save():
 (out/'report.json').write_text(json.dumps(report,indent=2)+'\n')
save()
try:
 # Probe the shared lock before starting; the unchanged wrapper owns the lock
 # throughout each actual child. Do not run this tool inside another wrapper.
 with (root/'selfhost/build/phase32/execution.lock').open('a') as lock:
  fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB);fcntl.flock(lock,fcntl.LOCK_UN)
 for mode,seconds,expected in [('memory',5,'tree-rss-limit'),('deadline',1,'deadline')]:
  target=out/mode;receipt=out/(mode+'-child.json')
  command=[sys.executable,str(wrapper),'--seconds',str(seconds),'--rss-mib','128',str(target),'--',sys.executable,str(child),mode,str(receipt)]
  row={'mode':mode,'command':command,'expectedStoppedFor':expected,'pass':False};report['cases'].append(row);save()
  with (out/(mode+'-supervisor.stdout')).open('w') as so,(out/(mode+'-supervisor.stderr')).open('w') as se:
   proc=subprocess.Popen(command,cwd=root,stdout=so,stderr=se,start_new_session=True)
   try:code=proc.wait(timeout=12)
   except subprocess.TimeoutExpired:
    row['emergencyCleanup']=True;cleanup(receipt)
    try:os.killpg(proc.pid,signal.SIGKILL)
    except ProcessLookupError:pass
    proc.wait(timeout=3);raise
  row['supervisorExitCode']=code;assert code==1,'expected negative supervisor result'
  raw=target/'run.json';bounded=json.loads(raw.read_text());row['supervisorReceipt']=ident(raw)
  assert bounded['complete'] is False;assert bounded['stoppedFor']==expected
  assert bounded['returncode']==-signal.SIGKILL
  info=json.loads(receipt.read_text());row['childReceipt']=ident(receipt);seen=state(info['pid'])
  row['childAbsent']=seen is None or seen['startTicks']!=info['startTicks'];row['pidObservation']=seen
  assert row['childAbsent'],'supervisor must reap the original child identity'
  row['peakTreeRssBytes']=bounded['peakTreeRssBytes'];row['wallSeconds']=bounded['wallSeconds'];row['stoppedFor']=bounded['stoppedFor']
  if mode=='memory':assert row['peakTreeRssBytes']>128*1024**2
  if mode=='deadline':assert row['peakTreeRssBytes']<128*1024**2
  row['pass']=True;save()
 for item in report['inputs']:assert ident(item['file'])==item
 report['complete']=True;report['pass']=True
except Exception as error:
 report['error']=repr(error)
 for mode in ['memory','deadline']:cleanup(out/(mode+'-child.json'))
 save();raise
finally:save()
print(json.dumps({'complete':report['complete'],'pass':report['pass'],'cases':[{k:r[k] for k in ['mode','pass','childAbsent','stoppedFor','peakTreeRssBytes']} for r in report['cases']]}))
