#!/usr/bin/env python3
"""Compare a selected exact parser vector with the released full baseline."""
from pathlib import Path
import hashlib,json,sys
ROOT=Path(__file__).resolve().parents[4]
validation=Path(sys.argv[1]);out=Path(sys.argv[2]);assert not out.exists()
paths={'reference':ROOT/'selfhost/build/phase8/reference-frontend-01/reference.json','baseline':ROOT/'selfhost/build/phase15/frontend-01/candidate.json','selectedReference':validation/'selected/reference.json','candidate':validation/'selected/candidate.json'}
raw={k:json.loads(p.read_text()) for k,p in paths.items()}
fields=['status','phase','checked','typeAccepted','proofTrust','kernelChecked','unsafeDefinitions','exitCode']
def key(r):return r['id'],r['lane']
def observation(r):
 x=r['result'];return {'verdict':r['status'],'evidence':r.get('evidence'),**{k:x.get(k) for k in fields},'diagnostic':x.get('diagnostic'),'output':x.get('output',x.get('stdout'))}
vectors={label:{key(r):observation(r) for r in value['results']} for label,value in raw.items()}
keys=vectors['candidate'].keys();assert keys==vectors['selectedReference'].keys()
for k in keys:assert vectors['reference'][k]==vectors['selectedReference'][k],k
for label in ['candidate','selectedReference']:
 r=raw[label];assert r['finished'] and not r['changedInputs'] and not r['identity']['changedArtifacts'] and not r['identity']['adapterChangedDuringRun']
 assert all(not w['errors'] and not w['stats']['failures'] and not w['stats']['timeouts'] for w in r['workers'])
 assert r['inventory']['revision']=='b2111cf43244e65f76ddc278ee695e669f720cbf'
new=[];lost=[];changed=[];remaining=[];semantic=[]
for k in sorted(keys):
 r,b,c=(vectors[n][k] for n in ['reference','baseline','candidate']);row={'id':k[0],'lane':k[1]}
 if b!=r and c==r:new.append(row)
 if b==r and c!=r:lost.append(row)
 if b!=c and c!=r:changed.append({**row,'before':b,'after':c,'reference':r})
 if c!=r:remaining.append({**row,'candidate':c,'reference':r})
 if any(b[x]!=c[x] for x in fields+['output']):semantic.append({**row,'before':b,'after':c})
report={'kind':'phase16-parser-exact-audit','complete':True,'pass':not lost and not semantic,'scope':'Only selected observations; root full-corpus gate owns coverage outside this selection. Strict diagnostics and harness verdict/evidence retained.','inputs':[{'role':k,'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for k,p in paths.items()]+[{'role':'tool','file':str(Path(__file__).resolve()),'sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest()}],'observations':len(keys),'exactBefore':sum(vectors['baseline'][k]==vectors['reference'][k] for k in keys),'exactAfter':sum(vectors['candidate'][k]==vectors['reference'][k] for k in keys),'newExact':new,'lostExact':lost,'changedStillNonexact':changed,'remaining':remaining,'semanticChanges':semantic}
out.write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({k:len(v) if isinstance(v,list) else v for k,v in report.items() if k not in ['inputs','scope']}))
