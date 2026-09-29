#!/usr/bin/env python3
from pathlib import Path
import json,hashlib,shutil,os,stat
r=Path(__file__).resolve().parents[4];root=r/'selfhost/build/phase17';out=root/'group-audit-01';out.mkdir();sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();load=lambda p:json.loads(p.read_text());ident=lambda p:{'file':str(p),'sha256':sha(p)}
report={'complete':False,'pass':False,'inputs':[ident(Path(__file__))]}
def read(p):report['inputs'].append(ident(p));return load(p)
def save():(out/'report.json').write_text(json.dumps(report,indent=2)+'\n')
save()
try:
 old=read(root/'group-baseline-03/report.json');new=read(root/'group-validation-01/report.json');assert old['complete'] and old['healthPass'] and new['complete'] and new['healthPass'];assert old['reference']['selectedComplete'] and new['reference']['selectedComplete'];assert old['observations']==new['observations']==196
 a=read(root/'group-baseline-03/selected/paired.json')['rows'];b=read(root/'group-validation-01/selected/paired.json')['rows'];key=lambda x:(x['id'],x['lane']);aa={key(x):x for x in a};bb={key(x):x for x in b};assert len(aa)==len(bb)==196 and aa.keys()==bb.keys();changed=[];lost=[];gained=[];unexpected=[]
 for k,x in aa.items():
  y=bb[k];assert x['reference']==y['reference'],k
  if x['exactAgreement'] and not y['exactAgreement']:lost.append(k)
  if not x['exactAgreement'] and y['exactAgreement']:gained.append(k)
  if x['candidate']!=y['candidate']:
   changed.append({'id':k[0],'lane':k[1],'before':x['candidate'],'after':y['candidate'],'nowExact':y['exactAgreement']})
   if not y['exactAgreement']:unexpected.append(k)
 focus=read(root/'group-checked-01/validation-001/report.json');assert focus['complete'] and focus['pass'];direct=read(root/'group-direct-01/report.json');assert direct['complete'] and direct['healthPass'];detail=read(root/'group-direct-01/controls/report.json');assert detail['complete'];m=read(root/'group-source-02/manifest.json');project=root/'group-source-02/project';parent=Path(m['parent'])
 def inventory(p):
  rows=[]
  for base,dirs,files in os.walk(p,followlinks=False):
   for name in dirs+files:
    f=Path(base)/name;s=f.lstat();rel=str(f.relative_to(p))
    if f.is_symlink():rows.append({'file':rel,'kind':'symlink','target':os.readlink(f),'mode':stat.S_IMODE(s.st_mode)})
    elif f.is_file():rows.append({'file':rel,'kind':'file','bytes':s.st_size,'sha256':sha(f),'mode':stat.S_IMODE(s.st_mode)})
  return sorted(rows,key=lambda x:x['file'])
 assert inventory(parent)==m['parentMembership'];assert inventory(project)==m['candidateMembership']
 attempt=read(root/'group-checked-01/attempt.json');assert attempt['config']['project']==str(project);assert sha(Path(attempt['api']['file']))==attempt['api']['sha256'];assert sha(root/'group-source-02/consumed-plan.md')==m['plan']['sha256']
 for row in attempt['snapshot']['sources']:
  for side in ['original','frozen']:assert sha(Path(row[side]['file']))==row[side]['sha256']
 report.update({'complete':True,'pass':not lost and not unexpected and direct['pass'],'rawOraclePass':new['pass'],'beforeExact':old['exact'],'afterExact':new['exact'],'observations':196,'lostExact':lost,'newExact':gained,'unexpectedChanges':unexpected,'changedRows':changed,'direct':{'controls':len(detail['controls']),'pass':direct['pass']},'sourceChanges':m['changes'],'conceptDelta':m['conceptDelta'],'api':attempt['api']})
 report['families']={name:{'observations':len(rows),'beforeExact':sum(aa[key(x)]['exactAgreement']for x in rows),'afterExact':sum(x['exactAgreement']for x in rows)}for name,rows in [('stage',[x for x in b if x['id'].startswith('rejected-stage/')]),('shape',[x for x in b if x['id'].startswith('group/')]),('pattern',[x for x in b if not x['id'].startswith(('rejected-stage/','group/'))])]}
except Exception as e:
 import traceback;report['error']=traceback.format_exc()
shutil.copy2(__file__,out/'consumed-tool.py');save();print(json.dumps({k:v for k,v in report.items()if k not in ['inputs','changedRows','api']},indent=2))
