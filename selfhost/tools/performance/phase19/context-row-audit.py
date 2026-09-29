#!/usr/bin/env python3
from pathlib import Path
import json,hashlib,os,stat,shutil,traceback
r=Path(__file__).resolve().parents[4];root=r/'selfhost/build/phase19';out=root/'context-row-audit-01';out.mkdir();sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();report=dict(complete=False,inputs=[]);report['pass']=False
def read(p):report['inputs'].append(dict(file=str(p),sha256=sha(p)));return json.loads(p.read_text())
def inv(p):
 rows=[]
 for base,dirs,files in os.walk(p,followlinks=False):
  for name in dirs+files:
   f=Path(base)/name;st=f.lstat();x=dict(file=str(f.relative_to(p)),mode=stat.S_IMODE(st.st_mode))
   if f.is_symlink():rows.append(dict(**x,kind='symlink',target=os.readlink(f)))
   elif f.is_file():rows.append(dict(**x,kind='file',bytes=st.st_size,sha256=sha(f)))
 return sorted(rows,key=lambda x:x['file'])
def healthy(x,allowed=(0,)):
 assert x['exitCode']in allowed and x['error']is None and x['signal']is None and not x['timedOut'] and not x['overflow']
try:
 oracle=read(root/'context-row-oracle-05/oracle/report.json');assert oracle['complete']and oracle['pass']and len(oracle['rows'])==35
 plan=read(root/'context-row-controls-05/cases.json')
 for c in plan['cases']:
  if 'original'in c:assert sha(Path(c['file']))==c['original']['sha256']==sha(Path(c['original']['file']))
  row=next(x for x in oracle['rows']if x['id']==c['id']);assert row['fullFile']['status']==row['status']
  if row['status']=='error':assert row['fullFile']['diagnostic']==row['failure']['raw']
 for name,count in [('context-row-probe-07',35),('context-row-body-01',40),('context-row-grammar-01',46),('context-row-state-01',27),('context-row-free-01',13)]:
  top=read(root/name/'report.json');assert top['complete']and top['healthPass']and top['pass']and top['rows']==count;healthy(top['execution'])
  d=read(root/name/'controls/report.json');assert d['complete']and d['pass']and all(x['pass']for x in d['rows'])
  if 'extension'in d:
   e=d['extension'];assert e['prefixUnchanged'];a=Path(e['production']['file']).read_bytes();b=Path(e['probe']['file']).read_bytes();assert b[:len(a)]==a;assert sha(Path(e['production']['file']))==e['production']['sha256'];assert sha(Path(e['probe']['file']))==e['probe']['sha256']
 detail=read(root/'context-row-probe-07/controls/report.json');assert detail['supported']==32 and detail['unsupportedControls']==3 and len(detail['direct'])==9 and all(x['pass']for x in detail['direct'])
 nested=next(x for x in detail['rows']if x['id']=='context-row/valid-nested-retained-field');assert nested['generatedActual']==[dict(name='_5',id=2147483653)];assert nested['generatedReference']==[dict(name='_5',id=5)];assert nested['state']['next']==6;assert nested['bindingGraph']['freeLexicalVariables']==0;assert any(x['id']==2147483653 for x in nested['bindingGraph']['uses'])
 for family in ['body','grammar']:
  d=read(root/f'context-row-{family}-01/controls/report.json');assert len(d['expandedControls'])==4
 raw=read(root/'context-row-raw-01/report.json');assert raw['complete']and raw['healthPass']and raw['pass']and raw['controls']==194;healthy(raw['execution'])
 sources=[]
 for n in ['01','02','03','04','05']:
  m=read(root/f'context-row-source-{n}/manifest.json');assert inv(Path(m['parent']))==m['parentMembership'];assert inv(root/f'context-row-source-{n}/project')==m['candidateMembership']
  for x in m['inputs']:assert sha(Path(x['file']))==x['sha256']
  b=read(root/f'context-row-build-{n}/build.json')
  if n=='01':
   assert not b['complete'];healthy(b['phases'][0]['execution'],(1,));sources.append(dict(source=n,changes=m['changes'],bootstrap=False));continue
  assert b['complete']
  for x in b['phases']:healthy(x['execution'])
  a=read(root/f'context-row-build-{n}/attempt.json');assert a['checked'];assert sha(Path(a['api']['file']))==a['api']['sha256'];assert sha(Path(a['checkedApi']['file']))==a['checkedApi']['sha256']
  for x in a['snapshot']['sources']:
   for side in ['original','frozen']:assert sha(Path(x[side]['file']))==x[side]['sha256']
  focused=read(root/f'context-row-build-{n}/validation-001/report.json');assert focused['complete']and focused['pass'];sources.append(dict(source=n,changes=m['changes'],checkedApi=a['checkedApi'],api=a['api']))
 final=read(root/'context-row-validation-01/report.json');assert final['complete']and not final['pass']and final['selected']['exactDifferences']==60
 for x in final['phases']:healthy(x['execution'],(0,1))
 old=read(r/'selfhost/build/phase18/cursor-validation-01/selected/paired.json');new=read(root/'context-row-validation-01/selected/paired.json');assert not new['complete']and not new['selectedComplete'];assert not new['missing'];assert len(new['rows'])==196
 key=lambda x:(x['id'],x['lane']);before={key(x):x for x in old['rows']};after={key(x):x for x in new['rows']};assert before.keys()==after.keys();gains=[];changed=[]
 for k,v in after.items():
  assert before[k]['reference']==v['reference'];assert not(before[k]['exactAgreement']and not v['exactAgreement'])
  if before[k]['candidate']!=v['candidate']:assert v['exactAgreement'];changed.append(k)
  if not before[k]['exactAgreement']and v['exactAgreement']:gains.append(k)
 expected={(f'group/{x}',lane)for x in ['nested-zero-head-match','zero-head-match','zero-head-match-argument','zero-head-match-lambda']for lane in ['parse','check']};assert set(gains)==set(changed)==expected
 statuses={}
 for side in ['reference','candidate']:
  attempt=new['attempts'][side];assert attempt['exitCode']==0 and attempt['signal']is None and attempt['error']is None;d=read(Path(attempt['file']));assert not d['changedInputs'];assert len(d['results'])==196
  for worker in d['workers']:assert not worker['errors'];assert worker['stats']['timeouts']==0 and worker['stats']['failures']==0
  statuses[side]=d['summary']['statuses']
 for name in ['context-row-oracle-01/oracle/report.json','context-row-probe-01/report.json','context-row-probe-02/controls/report.json','context-row-probe-04/controls/report.json','context-row-probe-05/controls/report.json']:
  failed=read(root/name);assert not failed['pass']
 for x in report['inputs']:assert sha(Path(x['file']))==x['sha256']
 report.update(dict(complete=True,sources=sources,privateFixtureRecords=35,privateAdmitted=32,privateUnsupported=3,directFlattenControls=9,bodyControls=40,namesControls=46,stateControls=27,materializationControls=13,rawControls=194,publicObservations=196,publicExactBefore=128,publicExactAfter=136,publicNewExact=gains,publicLostExact=[],publicRemainingDifferences=60,publicRawWorkflowPass=False,publicRawSelectedComplete=False,publicStatuses=statuses,scopedTermRelation='Binding-graph-checked alpha-equivalence with exact source/state; numeric generated IDs differ',generatedAllocation=dict(candidate=nested['generatedActual'],reference=nested['generatedReference'],next=6),productionLoaderRoutingChanged=False,mainMonadFixed=False,timingRun=False));report['pass']=True
except Exception:report['error']=traceback.format_exc()
shutil.copy2(__file__,out/'consumed-tool.py');(out/'report.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({k:v for k,v in report.items()if k not in ['inputs','sources']},indent=2))
if not report['pass']:raise SystemExit(1)
