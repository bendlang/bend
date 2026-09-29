#!/usr/bin/env python3
from pathlib import Path
import json,hashlib
r=Path(__file__).resolve().parents[4];b=r/'selfhost/build/phase16';j=lambda p:json.loads(p.read_text());ident=lambda p:{'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()};p0=b/'marked-pattern-validation-01/selected/paired.json';p1=b/'marked-pattern-integrated-01/selected/paired.json';old=j(p0);new=j(p1);a={(x['id'],x['lane']):x for x in old['rows']};z={(x['id'],x['lane']):x for x in new['rows']};assert a.keys()==z.keys();lost=[];gains=[];changes=[];primitive=[]
for key,x in z.items():
 y=a[key]
 if y['exactAgreement'] and not x['exactAgreement']:lost.append(key)
 if x['exactAgreement'] and not y['exactAgreement']:gains.append(key)
 if y['candidate']!=x['candidate']:changes.append({'id':key[0],'lane':key[1],'nowExact':x['exactAgreement'],'before':y['candidate'],'after':x['candidate']})
 for field in ['status','phase','checked','exitCode','typeAccepted','proofTrust']:
  if y['candidate'].get(field)!=x['candidate'].get(field):primitive.append({'id':key[0],'lane':key[1],'field':field,'before':y['candidate'].get(field),'after':x['candidate'].get(field),'reference':x['reference'].get(field)})
assert not lost;assert all(c['nowExact'] for c in changes);assert all(c['after']==c['reference']for c in primitive)
report=j(b/'marked-pattern-integrated-01/report.json');assert report['complete'];assert report['reference']['selectedComplete'];assert all(not w['errors']and w['stats']['failures']==0 and w['stats']['timeouts']==0 for side in ['reference','candidate'] for w in report[side]['workers']);direct=j(b/'marked-pattern-integrated-demand-01/report.json');assert direct['complete'] and direct['pass'];assert len(direct['rows'])==6
out=b/'marked-pattern-integration-audit-01.json';assert not out.exists();out.write_text(json.dumps({'complete':True,'pass':True,'scope':'Preserves isolated marked-pattern outcomes and lazy/quantity contracts in final compact union; known selected mismatches retained.','observations':len(z),'beforeExact':sum(x['exactAgreement']for x in a.values()),'afterExact':sum(x['exactAgreement']for x in z.values()),'newExact':gains,'lostExact':lost,'changedOutcomes':changes,'primitiveChanges':primitive,'directPass':6,'identities':[ident(p)for p in [Path(__file__),p0,p1,b/'marked-pattern-integrated-01/report.json',b/'marked-pattern-integrated-demand-01/report.json',b/'compact-final-build-01/attempt.json']]},indent=2)+'\n');print(out)
