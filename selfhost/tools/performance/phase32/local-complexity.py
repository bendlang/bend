#!/usr/bin/env python3
"""Static committed/snapshot source and emitted-byte accounting; no execution."""
from pathlib import Path
import hashlib, json, re, subprocess, sys
root=Path(__file__).resolve().parents[4]
phase=root/'selfhost/build/phase32'
out=Path(sys.argv[1]).resolve()
assert not out.exists()
def ident(p):
 p=Path(p);b=p.read_bytes();return {'file':str(p.resolve()),'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest()}
def stats(b):
 text=b.decode();lines=text.splitlines()
 return dict(physicalLines=len(lines),nonblankLines=sum(bool(x.strip()) for x in lines),bytes=len(b),**{field:len(re.findall(r'^'+word+r'\b',text,re.M)) for field,word in [('defs','def'),('laws','law'),('types','type')]})
def add(rows):
 return {**{k:sum(x['counts'][k] for x in rows) for k in rows[0]['counts']},'modules':len(rows)}
commit=subprocess.check_output(['git','rev-parse','5f3015d'],cwd=root,text=True).strip()
def blob(p):return subprocess.check_output(['git','show',commit+':'+p],cwd=root)
manifestBytes=blob('selfhost/src/compiler.json');manifest=json.loads(manifestBytes);names=manifest['modules'];assert len(names)==len(set(names))
baseline=[]
for name in names:
 p='selfhost/'+name;b=blob(p);baseline.append({'file':p,'git':commit+':'+p,'sha256':hashlib.sha256(b).hexdigest(),'counts':stats(b)})
r={'complete':False,'scope':'Manifest Bend physical/nonblank lines and top-level def/law/type declarations. Excludes generated images, runtime and experiment infrastructure; support reported separately. No compiler, generated program or benchmark execution.','inputs':[ident(__file__)],'baseline':{'commit':commit,'manifest':{'git':commit+':selfhost/src/compiler.json','sha256':hashlib.sha256(manifestBytes).hexdigest()},'files':baseline,'counts':add(baseline)},'attempts':{},'emitted':{},'gates':[]}
for tag in ['01','02','03']:
 attempt=phase/('attempt-'+tag);record=json.loads((attempt/'attempt.json').read_text());snapshot=Path(record['snapshot']['root']);mp=snapshot/'src/compiler.json';currentNames=json.loads(mp.read_text())['modules'];assert currentNames==names
 rows=[]
 for name in names:
  p=snapshot/name;rows.append({**ident(p),'counts':stats(p.read_bytes())})
 counts=add(rows)
 r['attempts'][tag]={'manifest':ident(mp),'receipt':ident(attempt/'attempt.json'),'files':rows,'counts':counts,'deltaFrom31':{k:counts[k]-r['baseline']['counts'][k] for k in counts},'sourceMatchesWorkingTree':all(Path(x['file']).read_bytes()==(root/'selfhost'/name).read_bytes() for x,name in zip(rows,names))}
 r['inputs'].append(ident(attempt/'attempt.json'))
for name in ['src/runtime/js/core.mjs','tools/stage0-library.mjs']:
 old=blob('selfhost/'+name);p=Path(json.loads((phase/'attempt-03/attempt.json').read_text())['snapshot']['root'])/name
 r.setdefault('support',[]).append({'name':name,'baselineSha256':hashlib.sha256(old).hexdigest(),'baselineCounts':stats(old),'candidate':ident(p),'candidateCounts':stats(p.read_bytes()),'identical':old==p.read_bytes()})
cohort=phase/'local-checked-03/derive.json';d=json.loads(cohort.read_text());assert d['complete'];r['inputs'].append(ident(cohort))
for name,c in d['cases'].items():
 rows={}
 for role,entry in c['variants'].items():
  found=ident(entry['file']);assert found==entry;rows[role]=found
 r['emitted'][name]={'cohort':rows,'delta03vs02':rows['record_vectors']['bytes']-rows['read_fusion']['bytes'],'delta03vs01':rows['record_vectors']['bytes']-rows['statements']['bytes'],'delta03vs07':rows['record_vectors']['bytes']-rows['baseline']['bytes'],'raw':{}}
 for tag in ['01','02','03']:
  p=phase/('emission-'+tag)/(name+'.mjs');receipt=Path(str(p)+'.json');j=json.loads(receipt.read_text());i=ident(p);assert j['complete'] and j['observation']['checked'] and j['output']['sha256']==i['sha256'];r['emitted'][name]['raw'][tag]={'module':i,'receipt':ident(receipt),'source':j['input']}
for name in ['scope','vectors']:
 r['emitted'][name]={'raw':{}}
 for tag in ['02','03']:
  p=phase/('emission-'+tag)/(name+'.mjs');receipt=Path(str(p)+'.json');j=json.loads(receipt.read_text());i=ident(p);assert j['complete'] and j['observation']['checked'] and j['output']['sha256']==i['sha256'];r['emitted'][name]['raw'][tag]={'module':i,'receipt':ident(receipt),'source':j['input']}
 r['emitted'][name]['delta03vs02']=r['emitted'][name]['raw']['03']['module']['bytes']-r['emitted'][name]['raw']['02']['module']['bytes']
for name in ['pair','fold','order','scope','vectors','types']:
 p=phase/'local-checked-controls-03'/name/'report.json';b=phase/'local-checked-controls-03'/(name+'-outer')/'run.json';g=json.loads(p.read_text());bounds=json.loads(b.read_text());assert g['complete'] and g['pass'] and bounds['complete'] and bounds['returncode']==0
 counts={k:len(g[k]) for k in ['oracle','oracles','state','boundaries','publicResults','observations','cases','negative','bridges'] if k in g}
 r['gates'].append({'name':name,'report':ident(p),'supervisor':ident(b),'complete':True,'pass':True,'counts':counts,'peakTreeRssBytes':bounds['peakTreeRssBytes'],'wallSeconds':bounds['wallSeconds'],'availableFloorBytes':bounds['availableFloorBytes'],'minimumAvailableBytes':bounds['minimumAvailableBytes']})
r['complete']=True;out.write_text(json.dumps(r,indent=2)+'\n')
print(json.dumps({'baseline':r['baseline']['counts'],'attempts':{k:{'counts':v['counts'],'delta':v['deltaFrom31'],'current':v['sourceMatchesWorkingTree']} for k,v in r['attempts'].items()},'emitted':{k:{'delta03vs02':v.get('delta03vs02'),'bytes':{kk:vv['bytes'] for kk,vv in v.get('cohort',{}).items()}} for k,v in r['emitted'].items()},'gates':[(x['name'],x['counts']) for x in r['gates']]}))
