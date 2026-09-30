#!/usr/bin/env python3
"""Explicit historical-verdict repair; reuse60 bound rows, acquire only21 native."""
from pathlib import Path
import hashlib,json,os,signal,subprocess,sys,time
planfile,out=(Path(x).resolve() for x in sys.argv[1:]);p=json.loads(planfile.read_text());out.mkdir(exist_ok=False)
root=Path(__file__).resolve().parents[4];priorfile=planfile.parent/'pilot/report.json';prior=json.loads(priorfile.read_text())
assert p['campaign']=='pilot' and p['expectedRows']==81
assert prior['complete'] and not prior['agreementComplete'] and prior['stopped']=='new failing or nonexact observation: pilot-js'
assert len(prior['rows'])==60 and len(prior['unexecuted'])==21 and not prior['incompleteBatchRows'] and not prior.get('error')
def ident(file):
 file=Path(file).resolve();raw=file.read_bytes();return {'file':str(file),'sha256':hashlib.sha256(raw).hexdigest(),'bytes':len(raw)}
inputs={x['file']:x for x in p['inputs']}
def retain(file,expected=None):
 item=ident(file)
 if expected is not None:assert item==expected
 inputs[item['file']]=item;return item
for file in [planfile,priorfile,Path(__file__),root/'design/phase30/backend-pilot-classification-repair.md']:retain(file)
def verify():
 for item in inputs.values():assert ident(item['file'])==item,item['file']
def read_batch(file):
 d=json.loads(Path(file).read_text());assert d['complete'] and not d.get('error') and d['changedInputs']==[]
 a_file=Path(file).parent/'archive.json';a=json.loads(a_file.read_text());assert a['verifiedFiles']>0 and a['verifiedFiles']==len(a['files'])
 assert ident(a['archive']['file'])['sha256']==a['archive']['sha256'];retain(file);retain(a_file);retain(a['archive']['file'])
 return d['rows']
old={};historical=[]
for i in range(1,8):
 file=root/f'selfhost/build/phase24/backend-candidate-pilot-{i:02d}/report.json';retain(file);d=json.loads(file.read_text());assert d['complete'] and not d.get('error')
 for row in d['rows']:
  key=(row['id'],row['lane']);assert key not in old;old[key]=row;historical.append(row)
assert len(old)==81
keys=['referenceVerdict','candidateVerdict','reference','candidate','exactAgreement','semanticAgreement']
na={'printer/let_in_argument_typ.bend','show/nullary_adt_table.bend','state/eval_curried_tree.bend','stuck/lte.bend'}
def compare(rows):
 seen=set()
 for row in rows:
  key=(row['id'],row['lane']);assert key not in seen;seen.add(key);ref=old[key]
  assert row['exactAgreement'] and row['semanticAgreement']
  assert {k:row[k] for k in keys}=={k:ref[k] for k in keys},key
  verdict=row['referenceVerdict'];assert verdict==row['candidateVerdict']
  if verdict=='not-applicable':assert row['id'] in na and row['lane'] in ['js','native']
  elif verdict=='fail':assert row['id'] in p['expectedSharedCheckFailures'] and row['lane']=='check'
  else:assert verdict=='pass'
 return seen
rows=[]
for step,batch in zip(prior['steps'],p['batches']):
 assert step['name']==batch['name'] and step['exitCode']==0 and not step.get('timeout');retain(step['receipt']['file'],step['receipt']);rows+=read_batch(step['receipt']['file'])
assert len(rows)==60;compare(rows)
for a,b in zip(rows,prior['rows']):assert all(a[k]==b[k] for k in ['id','lane',*keys])
batch=p['batches'][-1];assert batch['name']=='pilot-native' and len(batch['cases'])==21
command=list(batch['command']);assert command[-2]==batch['output'];command[-2]=str(out/'remaining-native')
frozen={'kind':'phase30-backend-classification-repair-plan','complete':True,'executed':False,'inputs':list(inputs.values()),'sourcePlan':ident(planfile),'reusedRows':60,'remainingRows':21,'command':command,'outerTimeoutSeconds':450,'terminationGraceSeconds':3,'expectedCounts':{'pass':69,'not-applicable':8,'fail':4}}
(out/'plan.json').write_text(json.dumps(frozen,indent=2)+'\n');(out/'consumed-tool.py').write_bytes(Path(__file__).read_bytes())
report={'kind':'phase30-backend-classification-repair','complete':False,'agreementComplete':False,'plan':ident(out/'plan.json'),'inputs':list(inputs.values()),'reusedRows':60,'rows':rows,'unexecuted':batch['cases'],'scope':'Unchanged historical complete observations; no verdict rewriting. Not full backend conformance.'}
def save(): (out/'report.json').write_text(json.dumps(report,indent=2)+'\n')
def stop(process):
 try:os.killpg(process.pid,signal.SIGTERM)
 except ProcessLookupError:return
 try:process.wait(timeout=3)
 except subprocess.TimeoutExpired:pass
 try:os.killpg(process.pid,signal.SIGKILL)
 except ProcessLookupError:pass
 process.wait()
process=None;start=time.monotonic();save()
try:
 verify();env={k:v for k,v in os.environ.items() if not k.startswith('BEND_') and k not in ['NODE_OPTIONS','NODE_PATH']}
 with (out/'native.stdout').open('w') as a,(out/'native.stderr').open('w') as b:
  process=subprocess.Popen(command,cwd=root,env=env,stdout=a,stderr=b,start_new_session=True)
  try:code=process.wait(timeout=max(.1,450-(time.monotonic()-start)))
  except subprocess.TimeoutExpired:report['timeout']=True;stop(process);code=process.returncode
 report['execution']={'command':command,'exitCode':code,'stdout':ident(out/'native.stdout'),'stderr':ident(out/'native.stderr')};save();assert code==0 and not report.get('timeout')
 new=read_batch(out/'remaining-native/report.json');assert len(new)==21
 assert {(r['id'],r['lane']) for r in new}=={(r['id'],r['lanes'][0]) for r in batch['cases']}
 rows+=new;assert compare(rows)==set(old);verify()
 report['rows']=rows;report['unexecuted']=[];report['counts']={v:sum(r['referenceVerdict']==v for r in rows) for v in ['pass','not-applicable','fail']};assert report['counts']==frozen['expectedCounts']
 report['inputs']=list(inputs.values());report['exactRows']=81;report['agreementComplete']=True;report['complete']=True
except BaseException as error:report['error']=repr(error)
finally:
 if process is not None:stop(process)
 report['wallSeconds']=time.monotonic()-start;save()
print(json.dumps({k:report.get(k) for k in ['complete','agreementComplete','exactRows','counts','error','wallSeconds']}))
raise SystemExit(0 if report['agreementComplete'] else 1)
