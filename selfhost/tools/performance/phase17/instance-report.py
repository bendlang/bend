import hashlib,json,sys
from pathlib import Path
root=Path(__file__).resolve().parents[4];out=root/'implementation/phase17';out.mkdir(exist_ok=True)
def read(s):return json.loads((root/s).read_text())
def ident(s):
 p=root/s;b=p.read_bytes();return {'file':str(p),'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest()}
pairs=['selfhost/build/phase17/instance-paired-01','selfhost/build/phase17/instance-nested-paired-01']
rows=[]
for p in pairs:
 report=read(p+'/report.json');assert report['complete'] and report['pass']
 rows.extend(read(p+'/selected/paired.json')['rows'])
memo=read('selfhost/build/phase17/instance-memo-01/report.json');assert memo['complete'] and memo['pass']
assert len(rows)==22 and sum(not r['exactAgreement'] for r in rows)==2 and all(r['semanticAgreement'] for r in rows)
source=['selfhost/src/check/kernel.bend','selfhost/src/check/specialize.bend','selfhost/src/diagnostic/trace.bend','selfhost/src/diagnostic/produce.bend','selfhost/src/driver/api.bend','selfhost/src/check/annotate.bend','selfhost/.bootstrap/upstream-phase8/bend2/bend.ts']
artifacts=['design/phase17/instance-chronology.md','design/phase17/instance-nested-witness.md','design/phase17/instance-shared-checker.md','selfhost/build/phase17/instance-controls-01/preparation-failure.json','selfhost/build/phase17/instance-controls-02/manifest.json','selfhost/build/phase17/instance-nested-01/manifest.json','selfhost/build/phase17/instance-memo-01/report.json','selfhost/build/phase17/instance-source-census-01/report.json']+[p+'/'+f for p in pairs for f in ['report.json','selected/paired.json','selected/reference.json','selected/candidate.json']]
r={'kind':'phase17-live-instance-chronology-investigation','complete':True,'compilerChanged':False,'cpu':1,'performanceClaim':False,'apiSha256':'35044ae6f6cd9bb63690536588c11761695c66cbf524db8bcd3baa6453ed5315','pinnedUpstream':'b2111cf43244e65f76ddc278ee695e669f720cbf','pairedObservations':len(rows),'exactAgreements':sum(x['exactAgreement'] for x in rows),'primitiveDifferences':sum(not x['semanticAgreement'] for x in rows),'strictDifferences':[x for x in rows if not x['exactAgreement']],'memoControls':{'count':len(memo['rows']),'allExact':all(x['exact'] for x in memo['rows']),'rows':memo['rows']},'falsifiedHypothesis':'The first nested witness fails outer x usage only at lambda exit; both compilers correctly reach its nested app first. The corrected local-lambda witness demonstrates the prewalk-order failure.','setupFailure':'Preparation01 guessed an absent pinned path; failure and partial fixtures retained. Corrected preparation02 precedes all compiler observations.','sourceCensus':read('selfhost/build/phase17/instance-source-census-01/report.json'),'sourceIdentities':[ident(s) for s in source],'evidence':[ident(s) for s in artifacts],'tool':ident(str(Path(__file__).relative_to(root))),'decision':'Proposal only: one authoritative checker with shared world and immediate instance checking, retaining source bodies and exact memo contract. No compiler implementation before root review.'}
p=out/'instance-chronology.json';assert not p.exists();p.write_text(json.dumps(r,indent=2)+'\n')
print(json.dumps({k:r[k] for k in ['complete','compilerChanged','pairedObservations','exactAgreements','primitiveDifferences']}))
