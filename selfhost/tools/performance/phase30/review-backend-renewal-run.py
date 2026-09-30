#!/usr/bin/env python3
"""Supervise a root-granted retained backend campaign without changing tests."""
from pathlib import Path
import hashlib,json,os,signal,subprocess,sys,time
planfile=Path(sys.argv[1]).resolve();p=json.loads(planfile.read_text());assert p['complete'] and not p['executed']
assert p['kind']=='phase30-retained-backend-renewal-plan' and p['campaign'] in ['pilot','broad-js']
assert p['outerTimeoutSeconds']<=(900 if p['campaign']=='pilot' else 1800)
assert p['terminationGraceSeconds']==3
root=Path(__file__).resolve().parents[4];out=planfile.parent/p['campaign'];out.mkdir(exist_ok=False)
def ident(file):
 file=Path(file).resolve();return {'file':str(file),'sha256':hashlib.sha256(file.read_bytes()).hexdigest(),'bytes':file.stat().st_size}
def verify():
 for item in p['inputs']:assert ident(item['file'])==item,item['file']
report={'kind':'phase30-retained-backend-renewal','complete':False,'agreementComplete':False,'campaign':p['campaign'],
 'plan':ident(planfile),'launcher':ident(Path(__file__)),'attempt':p['attempt'],'rowsExpected':p['expectedRows'],
 'terminationGraceSeconds':p['terminationGraceSeconds'],
 'steps':[],'rows':[],'incompleteBatchRows':[],'unexecuted':[{'batch':b['name'],**c} for b in p['batches'] for c in b['cases']],
 'scope':'Fresh selected paired observations. Expected shared check failures remain failures; exact agreement is distinct from fixture pass. No timing comparison.'}
def save(): (out/'report.json').write_text(json.dumps(report,indent=2)+'\n')
(out/'consumed-run.py').write_bytes(Path(__file__).read_bytes());save()
start=time.monotonic();deadline=start+p['outerTimeoutSeconds'];active=None
env={k:v for k,v in os.environ.items() if not k.startswith('BEND_') and k not in ['NODE_OPTIONS','NODE_PATH']}
def stop_group(process):
 try:os.killpg(process.pid,signal.SIGTERM)
 except ProcessLookupError:return
 try:process.wait(timeout=p['terminationGraceSeconds'])
 except subprocess.TimeoutExpired:pass
 try:os.killpg(process.pid,signal.SIGKILL)
 except ProcessLookupError:pass
 process.wait()
try:
 verify()
 for batch in p['batches']:
  remaining=deadline-time.monotonic()
  if remaining<=0:report['stopped']='campaign deadline before '+batch['name'];break
  assert Path(batch['output']).parent==out and not Path(batch['output']).exists()
  step={'name':batch['name'],'command':batch['command'],'complete':False,'outerRemainingSeconds':remaining,'started':time.time()};report['steps'].append(step);save()
  for case in batch['cases']:
   row={'batch':batch['name'],**case};report['unexecuted'].remove(row);report['incompleteBatchRows'].append(row)
  save()
  begin=time.monotonic();stdout=out/(batch['name']+'.stdout');stderr=out/(batch['name']+'.stderr')
  with stdout.open('w') as a,stderr.open('w') as b:
   process=subprocess.Popen(batch['command'],cwd=root,env=env,stdout=a,stderr=b,start_new_session=True);active=process
   try:step['exitCode']=process.wait(timeout=remaining)
   except subprocess.TimeoutExpired:
    step['timeout']=True;stop_group(process);step['exitCode']=process.returncode
  step.update(wallSeconds=time.monotonic()-begin,finished=time.time(),stdout=ident(stdout),stderr=ident(stderr));save()
  receipt=Path(batch['output'])/'report.json'
  if not receipt.exists():report['stopped']='missing batch report: '+batch['name'];break
  step['receipt']=ident(receipt);data=json.loads(receipt.read_text());step['rawComplete']=data.get('complete',False);step['rawPass']=data.get('pass')
  step['savedRows']=data.get('rows',[])
  step['rawSelectedFiles']=[ident(file) for file in (Path(batch['output'])/'selected').glob('*.json')]
  if step.get('timeout') or step['exitCode']!=0 or not data.get('complete') or data.get('error'):
   stop_group(process);report['stopped']='incomplete batch: '+batch['name'];break
  assert data['changedInputs']==[], 'Census helper reported changed inputs'
  archivefile=Path(batch['output'])/'archive.json';archive=json.loads(archivefile.read_text())
  assert archive['verifiedFiles']>0 and archive['verifiedFiles']==len(archive['files'])
  assert ident(archive['archive']['file'])['sha256']==archive['archive']['sha256']
  step['archiveReceipt']=ident(archivefile);step['archive']=ident(archive['archive']['file'])
  rows=data['rows'];assert len(rows)==len(batch['cases'])
  observed=[(r['id'],r['lane']) for r in rows];expected=[(c['id'],c['lanes'][0]) for c in batch['cases']]
  assert len(set(observed))==len(observed) and set(observed)==set(expected)
  accepted=True
  for row in rows:
   recorded={'batch':batch['name'],**row};report['rows'].append(recorded)
   report['incompleteBatchRows'].remove({'batch':batch['name'],'id':row['id'],'lanes':[row['lane']]})
   shared=row['lane']=='check' and row['id'] in p['expectedSharedCheckFailures']
   valid=row['exactAgreement'] and ((row['referenceVerdict']==row['candidateVerdict']=='fail' and row['reference']['phase']==row['candidate']['phase']=='check' and row['reference']['checked'] and row['candidate']['checked']) if shared else row['referenceVerdict']==row['candidateVerdict']=='pass')
   recorded['expectedSharedCheckFailure']=shared;recorded['acceptedCampaignObservation']=bool(valid)
   accepted=accepted and valid
  step['complete']=bool(accepted);save()
  if not accepted:report['stopped']='new failing or nonexact observation: '+batch['name'];break
  verify()
 report['agreementComplete']=len(report['rows'])==p['expectedRows'] and not report['unexecuted'] and not report['incompleteBatchRows'] and all(r['acceptedCampaignObservation'] for r in report['rows'])
 report['exactRows']=sum(r['exactAgreement'] for r in report['rows'])
 report['fixtureExecutionPasses']=sum(r['lane']!='check' and r['referenceVerdict']==r['candidateVerdict']=='pass' for r in report['rows'])
 report['sharedRawCheckFailures']=sum(r['expectedSharedCheckFailure'] for r in report['rows'])
 verify();report['complete']=True
except BaseException as error:
 report['error']=repr(error)
finally:
 if active is not None:stop_group(active)
 report['wallSeconds']=time.monotonic()-start;save()
print(json.dumps({k:report.get(k) for k in ['complete','agreementComplete','exactRows','fixtureExecutionPasses','sharedRawCheckFailures','stopped','error','wallSeconds']}))
raise SystemExit(0 if report['agreementComplete'] else 1)
