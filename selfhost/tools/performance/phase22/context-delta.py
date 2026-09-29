#!/usr/bin/env python3
"""Exact frozen-vector comparison, with primitive changes reported separately."""
from pathlib import Path
import sys,json,hashlib
old,new,out=map(Path,sys.argv[1:]);a=json.loads(old.read_text());b=json.loads(new.read_text());aid={r['id']+'@'+r['lane']:r for r in a['rows']};bid={r['id']+'@'+r['lane']:r for r in b['rows']};assert aid.keys()==bid.keys()
def h(p):return {'file':str(p.resolve()),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
axes=['status','phase','checked','typeAccepted','proofTrust','kernelChecked','unsafeDefinitions','exitCode']
def prim(v):return {k:v.get(k) for k in axes}
res={'complete':True,'inputs':[h(old),h(new),h(Path(__file__))],'observations':len(aid),'baselineExact':sum(r['exactAgreement'] for r in aid.values()),'candidateExact':sum(r['exactAgreement']for r in bid.values()),'gained':[],'lost':[],'referenceChanged':[],'primitiveChanged':[],'remaining':[]}
for k,r in bid.items():
 q=aid[k]
 if q['reference']!=r['reference']:res['referenceChanged'].append(k)
 if not q['exactAgreement']and r['exactAgreement']:res['gained'].append(k)
 if q['exactAgreement']and not r['exactAgreement']:res['lost'].append(k)
 if prim(q['candidate'])!=prim(r['candidate']):res['primitiveChanged'].append({'id':k,'matchesReference':prim(r['reference'])==prim(r['candidate']),'before':prim(q['candidate']),'after':prim(r['candidate'])})
 if not r['exactAgreement']:res['remaining'].append({'id':k,'primitiveAgreement':prim(r['reference'])==prim(r['candidate']),'reference':r['reference'],'candidate':r['candidate']})
res['pass']=not res['lost']and not res['referenceChanged']and all(x['matchesReference']for x in res['primitiveChanged'])
out.write_text(json.dumps(res,indent=2)+'\n');print(json.dumps({k:len(v)if isinstance(v,list)else v for k,v in res.items()if k not in ['inputs','remaining']}))
