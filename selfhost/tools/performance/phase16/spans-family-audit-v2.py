#!/usr/bin/env python3
"""Independently compare frozen raw checker-family vectors without compiler jobs."""
import hashlib,json,sys
from pathlib import Path
root=Path(sys.argv[1]).resolve()
selection=Path(sys.argv[2]).resolve()
paths=[root/'selected/reference.json',root/'selected/candidate.json',root/'selected/paired.json',selection]
r,c,p,s=[json.loads(x.read_text()) for x in paths]
def keyed(rows):
 out={(x['id'],x['lane']):x for x in rows}
 assert len(out)==len(rows), 'duplicate row'
 return out
rr,cc,pp=map(keyed,[r['results'],c['results'],p['rows']])
keys=set(keyed(s['cases']))
assert keys==rr.keys()==cc.keys()==pp.keys()
for raw in [r,c]:
 assert raw['selectedComplete'] and not raw['changedInputs']
 assert raw['summary']['probes']==len(keys)
 assert set(keyed(raw['selection']['requested']))==keys
 for worker in raw['workers']:
  assert not worker['errors']
  for field in ['failures','timeouts']:
   assert worker['stats'][field]==0
axes=['status','phase','checked','typeAccepted','proofTrust','kernelChecked','unsafeDefinitions','exitCode','output']
rows=[]
for k in sorted(keys):
 a,b=rr[k]['result'],cc[k]['result']
 dif=[x for x in axes if a.get(x)!=b.get(x)]
 exact=a.get('diagnostic')==b.get('diagnostic')
 assert exact==pp[k]['exactAgreement']
 rows.append({'id':k[0],'lane':k[1],'diagnosticExact':exact,'primitiveDifferences':dif})
report={'kind':'phase16-source-span-family-independent-audit','complete':True,'pass':not any(x['primitiveDifferences'] for x in rows),'inputs':[{'file':str(x),'sha256':hashlib.sha256(x.read_bytes()).hexdigest()} for x in [Path(__file__).resolve(),*paths]],'observations':len(rows),'newExact':sum(x['diagnosticExact'] for x in rows),'remainingStrictDifferences':sum(not x['diagnosticExact'] for x in rows),'primitiveDifferences':sum(bool(x['primitiveDifferences']) for x in rows),'rows':rows,'scope':'Exact diagnostics and primitive results independently compared for all169 previously nonexact assigned rows; this is not a full frontend gate.'}
assert report['observations']==169
(root/'independent-audit.json').write_text(json.dumps(report,indent=2)+'\n')
(root/'independent-audit.py').write_bytes(Path(__file__).read_bytes())
print(json.dumps({k:v for k,v in report.items() if k not in ['inputs','rows']}))
