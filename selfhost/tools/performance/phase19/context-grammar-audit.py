#!/usr/bin/env python3
from pathlib import Path
import json,hashlib,os,stat,shutil
r=Path(__file__).resolve().parents[4];root=r/'selfhost/build/phase19';out=root/'context-grammar-audit-01';out.mkdir();sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();report={'complete':False,'pass':False,'inputs':[]}
def read(p):report['inputs'].append(dict(file=str(p),sha256=sha(p)));return json.loads(p.read_text())
def inv(p):
 rows=[]
 for base,dirs,files in os.walk(p,followlinks=False):
  for name in dirs+files:
   f=Path(base)/name;s=f.lstat();x=dict(file=str(f.relative_to(p)),mode=stat.S_IMODE(s.st_mode))
   if f.is_symlink():rows.append(dict(**x,kind='symlink',target=os.readlink(f)))
   elif f.is_file():rows.append(dict(**x,kind='file',bytes=s.st_size,sha256=sha(f)))
 return sorted(rows,key=lambda x:x['file'])
def healthy(p,exitCode=0):
 assert p['error'] is None and p['signal'] is None and not p['timedOut'] and not p['overflow'];assert p['exitCode']==exitCode
try:
 oracle=read(root/'context-grammar-oracle-01/oracle/report.json');assert oracle['complete'] and oracle['pass'] and len(oracle['rows'])==46
 for name,count in [('context-grammar-probe-01',46),('context-grammar-stage1-01',27)]:
  top=read(root/name/'report.json');assert top['complete'] and top['healthPass'] and top['pass'] and top['rows']==count;healthy(top['execution'])
  d=read(root/name/'controls/report.json');assert all(x['pass']for x in d['rows']);assert d['siblingStable'] and d['contextInputRefused']
 detail=read(root/'context-grammar-probe-01/controls/report.json');assert detail['supported']==32 and detail['unsupportedControls']==14
 raw=read(root/'context-grammar-raw-01/report.json');assert raw['complete'] and raw['healthPass'] and raw['pass'] and raw['controls']==194;healthy(raw['execution'])
 sources=[]
 for num in ['01','02']:
  m=read(root/f'context-grammar-source-{num}/manifest.json');assert inv(Path(m['parent']))==m['parentMembership'];assert inv(root/f'context-grammar-source-{num}/project')==m['candidateMembership']
  for x in m['inputs']:assert sha(Path(x['file']))==x['sha256']
  b=read(root/f'context-grammar-build-{num}/build.json')
  if num=='01':
   assert not b['complete'];assert len(b['phases'])==1;healthy(b['phases'][0]['execution'],1)
   err=root/'context-grammar-build-01/bootstrap/stderr';assert 'no law named f_args_existing' in err.read_text();report['inputs'].append(dict(file=str(err),sha256=sha(err)))
   sources.append(dict(source=num,changes=m['changes'],bootstrapPassed=False));continue
  a=read(root/f'context-grammar-build-{num}/attempt.json');assert a['checked'];assert sha(Path(a['api']['file']))==a['api']['sha256'];assert sha(Path(a['checkedApi']['file']))==a['checkedApi']['sha256'];assert a['config']['project']==str(root/f'context-grammar-source-{num}/project')
  for s in a['snapshot']['sources']:
   for side in ['original','frozen']:assert sha(Path(s[side]['file']))==s[side]['sha256']
  assert b['complete']
  for p in b['phases']:healthy(p['execution'])
  f=read(root/f'context-grammar-build-{num}/validation-001/report.json');assert f['complete'] and f['pass']
  sources.append(dict(source=num,changes=m['changes'],checkedApi=a['checkedApi'],api=a['api']))
 for x in report['inputs']:assert sha(Path(x['file']))==x['sha256']
 report.update(dict(complete=True,pass=True,sources=sources,supportedOracleRecords=32,unsupportedContractRecords=14,stage1Controls=27,rawControls=194,knownFailedAttempt=dict(source='01',cause='Renamed existing grammar workers lacked their old named laws; source02 supplies explicit signatures'),semanticBodyImplemented=False,productionLoaderRoutingChanged=False,timingRun=False,scope='Private existing-grammar names/calls; no Core result'))
except Exception:
 import traceback;report['error']=traceback.format_exc()
shutil.copy2(__file__,out/'consumed-tool.py');(out/'report.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({k:v for k,v in report.items()if k not in ['inputs','sources']},indent=2))
if not report['pass']:raise SystemExit(1)
