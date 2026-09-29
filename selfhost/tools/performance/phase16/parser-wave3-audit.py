#!/usr/bin/env python3
"""Audit the parser candidate against the exact post-origin wave3 frontier."""
from pathlib import Path
import hashlib,json,sys
ROOT=Path(__file__).resolve().parents[4];V=Path(sys.argv[1]);OUT=Path(sys.argv[2]);assert not OUT.exists()
paths={'reference':ROOT/'selfhost/build/phase8/reference-frontend-01/reference.json','baseline':ROOT/'selfhost/build/phase16/wave3-frontend-01/candidate.json','selectedReference':V/'selected/reference.json','candidate':V/'selected/candidate.json'}
raw={k:json.loads(p.read_text()) for k,p in paths.items()};fields=['status','phase','checked','typeAccepted','proofTrust','kernelChecked','unsafeDefinitions','exitCode']
def key(r):return r['id'],r['lane']
def obs(r):
 x=r['result'];return {'verdict':r['status'],'evidence':r.get('evidence'),**{k:x.get(k) for k in fields},'diagnostic':x.get('diagnostic'),'output':x.get('output',x.get('stdout'))}
v={k:{key(r):obs(r) for r in x['results']} for k,x in raw.items()};keys=v['candidate'].keys();assert keys==v['selectedReference'].keys()
for k in keys:assert v['reference'][k]==v['selectedReference'][k],k
for k in ['candidate','selectedReference','baseline']:
 x=raw[k];assert x['finished'] and not x['changedInputs'] and not x['identity']['changedArtifacts'] and not x['identity']['adapterChangedDuringRun'];assert all(not w['errors'] and not w['stats']['failures'] and not w['stats']['timeouts'] for w in x['workers'])
new=[];lost=[];remaining=[];semantic=[]
for k in sorted(keys):
 r,b,c=(v[n][k] for n in ['reference','baseline','candidate']);row={'id':k[0],'lane':k[1]}
 if b!=r and c==r:new.append(row)
 if b==r and c!=r:lost.append(row)
 if c!=r:remaining.append({**row,'candidate':c,'reference':r})
 if any(b[x]!=c[x] for x in fields+['output']):semantic.append(row)
x={'kind':'phase16-parser-wave3-audit','complete':True,'pass':not lost and not semantic,'scope':'244 selected observations only; no wider full-corpus guarantee. Baseline is independently gated integration04 wave3.','inputs':[{'role':k,'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for k,p in paths.items()]+[{'role':'tool','file':str(Path(__file__).resolve()),'sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest()}],'observations':len(keys),'exactBefore':sum(v['baseline'][k]==v['reference'][k] for k in keys),'exactAfter':sum(v['candidate'][k]==v['reference'][k] for k in keys),'newExact':new,'lostExact':lost,'remaining':remaining,'semanticChanges':semantic};OUT.write_text(json.dumps(x,indent=2)+'\n');print(json.dumps({k:len(z) if isinstance(z,list) else z for k,z in x.items() if k not in ['inputs','scope']}))
