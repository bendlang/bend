"""Bind the closed independent prefix controls; live-checker suite stays pending."""
from pathlib import Path
import hashlib,json
root=Path(__file__).resolve().parents[4];build=root/'selfhost/build/phase19'
def read(name):return json.loads((build/name/'result/report.json').read_text())
eo=read('instance-boundary-oracle-01');ep=read('instance-boundary-exact-parent-01');ec=read('instance-boundary-exact-candidate-01')
po=read('instance-boundary-proof-oracle-01');pp=read('instance-boundary-proof-parent-01');pc=read('instance-boundary-proof-candidate-01')
assert all(r['complete'] for r in [eo,ep,ec,po,pp,pc])
assert all(r['pass'] for r in [eo,ec,po,pc]) and not ep['pass'] and not pp['pass']
failed=[r['name'] for r in ep['rows'] if not r['pass']]
assert failed==['nat-payload','u32-payload','string-payload','lambda-affine-presence','lambda-many-presence']
assert pp['acceptedInvalidCachedProof'] and not pc['acceptedInvalidCachedProof']
assert ep['api']['sha256']==pp['api']['sha256'] and ec['api']['sha256']==pc['api']['sha256']
dirs=['instance-boundary-inputs-01','instance-boundary-proof-inputs-01','instance-boundary-oracle-01','instance-boundary-exact-parent-01','instance-boundary-exact-candidate-01','instance-boundary-proof-oracle-01','instance-boundary-proof-parent-01','instance-boundary-proof-candidate-01']
files=[p for d in dirs for p in sorted((build/d).rglob('*')) if p.is_file()]
files+=sorted((root/'selfhost/tools/performance/phase19').glob('instance-boundary-*'))
files+=[root/'implementation/phase19/instance-boundary.md']
def identity(p):return {'file':str(p.resolve()),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
report={'kind':'phase19-prefix-identity-and-proof-boundary-receipt','complete':True,'pass':True,'scope':'Closed isolated prefix correction only; prepared full live-checker boundary suite remains unrun.','parentAPI':ep['api'],'candidateAPI':ec['api'],'direct':{'controls':len(ec['rows']),'parentFailed':failed,'candidateAllPass':True,'symmetric':True},'proof':{'pinnedOriginalAccepted':po['results']['original']['accepted'],'pinnedChangedAccepted':po['results']['changed']['accepted'],'parent':pp['results'],'candidate':pc['results'],'parentAcceptedInvalidCachedProof':True,'candidateAcceptedInvalidCachedProof':False},'processesClosed':True,'failedParentEvidenceRetained':True,'pin':eo['pin'],'boundFiles':[identity(p) for p in sorted(set(files))],'promotion':'Not performed by this owner; no speed or whole-conformance claim.'}
out=root/'implementation/phase19/instance-boundary.json';assert not out.exists();out.write_text(json.dumps(report,indent=2)+'\n')
for x in report['boundFiles']:assert identity(Path(x['file']))==x
print(json.dumps({'file':str(out),'sha256':identity(out)['sha256'],'boundFiles':len(report['boundFiles'])}))
