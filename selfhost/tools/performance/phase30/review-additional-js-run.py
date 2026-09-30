#!/usr/bin/env python3
"""Parent-granted NEW JS coverage, serial bounded batches and raw verdicts."""
from pathlib import Path
import hashlib,importlib.util,json,os,shutil,signal,subprocess,sys,time
planfile=Path(sys.argv[1]).resolve();p=json.loads(planfile.read_text())
assert p['kind']=='phase30-additional-js-coverage-plan' and p['complete'] and not p['executed'] and p['expectedRows']==811
assert p['outerTimeoutSeconds']==1800 and p['terminationGraceSeconds']==3 and p['retainedBytesStop']==200*1024**2 and p['minimumFreeBytes']==150*1024**2
root=Path(__file__).resolve().parents[4];out=planfile.parent/'execution';out.mkdir(exist_ok=False)
def ident(file):
 file=Path(file).resolve();raw=file.read_bytes();return {'file':str(file),'sha256':hashlib.sha256(raw).hexdigest(),'bytes':len(raw)}
inputs=[*p['inputs'],ident(planfile)]
def verify():
 for item in inputs:assert ident(item['file'])==item,item['file']
assert ident(p['policy']['file'])==p['policy']
spec=importlib.util.spec_from_file_location('phase30_additional_js_policy',p['policy']['file']);policy=importlib.util.module_from_spec(spec);spec.loader.exec_module(policy)
fixtures={x['id']:x for x in p['fixtures']};expected=[{'batch':b['name'],**c} for b in p['batches'] for c in b['cases']]
assert len(expected)==811 and len(fixtures)==811
report={'kind':'phase30-additional-js-coverage','complete':False,'coverageComplete':False,'plan':ident(planfile),'inputs':inputs,'scope':p['scope'],'rowsExpected':811,'steps':[],'observations':[],'incompleteBatchRows':[],'neverStarted':expected.copy()}
def save(): (out/'report.json').write_text(json.dumps(report,indent=2)+'\n')
def retained_bytes():return sum(x.stat().st_size for x in out.rglob('*') if x.is_file())
def stop(process):
 try:os.killpg(process.pid,signal.SIGTERM)
 except ProcessLookupError:return
 try:process.wait(timeout=3)
 except subprocess.TimeoutExpired:pass
 try:os.killpg(process.pid,signal.SIGKILL)
 except ProcessLookupError:pass
 process.wait()
def archive_check(directory):
 af=directory/'archive.json';a=json.loads(af.read_text());assert a['verifiedFiles']>0 and a['verifiedFiles']==len(a['files'])
 assert ident(a['archive']['file'])['sha256']==a['archive']['sha256'];return {'receipt':ident(af),'archive':ident(a['archive']['file']),'verifiedFiles':a['verifiedFiles']}
def rowmaps(data):
 result={}
 for side in ['reference','candidate']:
  rows=data.get('sideResults',{}).get(side,[]);result[side]={(r.get('id'),r.get('lane')):r for r in rows}
  assert len(result[side])==len(rows),'duplicate '+side+' observations'
 return result
(out/'consumed-run.py').write_bytes(Path(__file__).read_bytes());save();start=time.monotonic();deadline=start+1800;active=None
env={k:v for k,v in os.environ.items() if not k.startswith('BEND_') and k not in ['NODE_OPTIONS','NODE_PATH']}
try:
 verify()
 for batch in p['batches']:
  remain=deadline-time.monotonic();used=retained_bytes();free=shutil.disk_usage(out).free
  if remain<=0:report['stopped']='campaign deadline';break
  if used>=p['retainedBytesStop']:report['stopped']='retained evidence pre-batch limit';break
  if free<p['minimumFreeBytes']:report['stopped']='free-space pre-batch reserve';break
  directory=Path(batch['output']);assert directory.parent==out and not directory.exists()
  step={'name':batch['name'],'command':batch['command'],'complete':False,'started':time.time(),'outerRemainingSeconds':remain,'retainedBytesBefore':used,'freeBytesBefore':free};report['steps'].append(step)
  for case in batch['cases']:
   item={'batch':batch['name'],**case};report['neverStarted'].remove(item);report['incompleteBatchRows'].append(item)
  save();begin=time.monotonic();stdout=out/(batch['name']+'.stdout');stderr=out/(batch['name']+'.stderr')
  with stdout.open('w') as a,stderr.open('w') as b:
   active=subprocess.Popen(batch['command'],cwd=root,env=env,stdout=a,stderr=b,start_new_session=True)
   try:step['exitCode']=active.wait(timeout=max(.1,deadline-time.monotonic()))
   except subprocess.TimeoutExpired:step['timeout']=True;stop(active);step['exitCode']=active.returncode
  step.update(wallSeconds=time.monotonic()-begin,finished=time.time(),stdout=ident(stdout),stderr=ident(stderr));save()
  rf=directory/'report.json'
  if not rf.exists():report['stopped']='missing helper report: '+batch['name'];break
  data=json.loads(rf.read_text());step['receipt']=ident(rf);step['rawComplete']=data.get('complete');step['rawError']=data.get('error');step['rawVerdicts']=data.get('sideSummary');step['rawRows']=data.get('rows',[])
  # Retain partial child receipts even when its complete flag was never written.
  step['savedSelectedFiles']=[ident(x) for x in (directory/'selected').glob('*.json')]
  maps=rowmaps(data);wanted={(c['id'],'js') for c in batch['cases']};seen=set();classified=[]
  for pair in data.get('rows',[]):
   key=(pair.get('id'),pair.get('lane'));assert key in wanted and key not in seen,'unexpected/duplicate paired row';seen.add(key)
   if key not in maps['reference'] or key not in maps['candidate']:continue
   item=policy.observe(pair,maps['reference'][key],maps['candidate'][key],fixtures[key[0]],p);item['batch']=batch['name'];classified.append(item);report['observations'].append(item)
   report['incompleteBatchRows'].remove({'batch':batch['name'],'id':key[0],'lanes':['js']})
  step['classifiedRows']=len(classified);save()
  if step.get('timeout') or step['exitCode']!=0 or not data.get('complete') or data.get('error'):
   report['stopped']='incomplete helper/process: '+batch['name'];break
  assert data.get('changedInputs')==[],'helper changed inputs';step['archive']=archive_check(directory);save()
  assert seen==wanted and set(maps['reference'])==wanted and set(maps['candidate'])==wanted and len(classified)==len(wanted),'incomplete row identities'
  # All raw rows are saved before rejecting even the first unknown field/error.
  if not all(x['accepted'] for x in classified):report['stopped']='new mismatch, unaccepted verdict or host observation: '+batch['name'];break
  verify();step['complete']=True;save()
 report['coverageComplete']=len(report['observations'])==811 and not report['neverStarted'] and not report['incompleteBatchRows'] and all(x['accepted'] for x in report['observations']) and all(x['complete'] for x in report['steps'])
 verify();report['complete']=True
except BaseException as error:report['error']=repr(error)
finally:
 if active is not None:stop(active)
 report['wallSeconds']=time.monotonic()-start;report['retainedBytes']=retained_bytes();report['freeBytes']=shutil.disk_usage(out).free
 report['counts']={side:{v:sum(str(x[side+'Verdict'])==v for x in report['observations']) for v in sorted({str(x[side+'Verdict']) for x in report['observations']})} for side in ['reference','candidate']}
 report['acceptedCounts']={v:sum(x['accepted'] and x['classification']==v for x in report['observations']) for v in ['pass','not-applicable']};save()
print(json.dumps({k:report.get(k) for k in ['complete','coverageComplete','counts','acceptedCounts','stopped','error','wallSeconds','retainedBytes']}))
raise SystemExit(0 if report['coverageComplete'] else 1)
