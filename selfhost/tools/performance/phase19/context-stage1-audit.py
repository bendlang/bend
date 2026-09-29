#!/usr/bin/env python3
from pathlib import Path
import json,hashlib,os,stat,shutil,re
r=Path(__file__).resolve().parents[4];root=r/'selfhost/build/phase19';out=root/'context-stage1-audit-01';out.mkdir();sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();report={'complete':False,'pass':False,'inputs':[]}
def read(p):report['inputs'].append({'file':str(p),'sha256':sha(p)});return json.loads(p.read_text())
def inv(p):
 rows=[]
 for base,dirs,files in os.walk(p,followlinks=False):
  for name in dirs+files:
   f=Path(base)/name;s=f.lstat();x={'file':str(f.relative_to(p)),'mode':stat.S_IMODE(s.st_mode)}
   if f.is_symlink():rows.append({**x,'kind':'symlink','target':os.readlink(f)})
   elif f.is_file():rows.append({**x,'kind':'file','bytes':s.st_size,'sha256':sha(f)})
 return sorted(rows,key=lambda x:x['file'])
def healthy(p):
 assert p['error'] is None and p['signal'] is None and not p['timedOut'] and not p['overflow'];assert p['exitCode'] in [0,1]
try:
 oracle=read(root/'context-oracle-01/oracle/report.json');assert oracle['complete'] and oracle['pass'] and len(oracle['rows'])==27
 bad=read(root/'context-probe-01/report.json');assert bad['complete'] and bad['healthPass'] and not bad['pass'];assert bad['failed']==['underscore'];healthy(bad['execution'])
 good=read(root/'context-probe-02/report.json');assert good['complete'] and good['healthPass'] and good['pass'];healthy(good['execution'])
 detail=read(root/'context-probe-02/controls/report.json');assert detail['supported']==23 and detail['unsupportedControls']==4 and detail['siblingStable'] and detail['contextInputRefused'];assert all(x['pass']for x in detail['rows'])
 raw=read(root/'context-raw-01/report.json');assert raw['complete'] and raw['healthPass'] and raw['pass'] and raw['controls']==194;healthy(raw['execution'])
 sources=[]
 for num in ['01','02']:
  m=read(root/f'context-source-{num}/manifest.json');assert inv(Path(m['parent']))==m['parentMembership'];assert inv(root/f'context-source-{num}/project')==m['candidateMembership']
  for x in m['inputs']:assert sha(Path(x['file']))==x['sha256']
  a=read(root/f'context-build-{num}/attempt.json');assert a['checked'];assert sha(Path(a['api']['file']))==a['api']['sha256'];assert a['config']['project']==str(root/f'context-source-{num}/project')
  for s in a['snapshot']['sources']:
   for side in ['original','frozen']:assert sha(Path(s[side]['file']))==s[side]['sha256']
  b=read(root/f'context-build-{num}/build.json');assert b['complete']
  for p in b['phases']:healthy(p['execution']);assert p['execution']['exitCode']==0
  f=read(root/f'context-build-{num}/validation-001/report.json');assert f['complete'] and f['pass']
  sources.append({'source':num,'changes':m['changes'],'checkedApi':a['checkedApi'],'api':a['api']})
 for x in report['inputs']:assert sha(Path(x['file']))==x['sha256']
 report.update({'complete':True,'pass':True,'sources':sources,'supportedOracleRecords':23,'unsupportedContractRecords':4,'rawControls':194,'knownFailedAttempt':{'source':'01','control':'underscore','cause':'Header underscore ID is allocated but underscore must not enter lexical stack'},'semanticBodyImplemented':False,'productionRoutingChanged':False,'timingRun':False,'scope':'Private fixed names/state protocol only'})
except Exception:
 import traceback;report['error']=traceback.format_exc()
shutil.copy2(__file__,out/'consumed-tool.py');(out/'report.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({k:v for k,v in report.items()if k not in ['inputs','sources']},indent=2))
if not report['pass']:raise SystemExit(1)
