"""Verify protected state, frozen coverage and external historical identities after capture."""
from pathlib import Path
import json,hashlib,subprocess
R=Path(__file__).resolve().parents[3];E=Path(__file__).resolve().parent
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
read=lambda p:json.loads(p.read_text())
ident=lambda p:{'path':str(p.relative_to(R)),'sha256':sha(p),'bytes':p.stat().st_size}
out=E/'post-capture-audit.json';assert not out.exists()
inv=read(E/'capsule-01/inventory.json');idx={x['path']:x for x in inv['members']}
m=read(E/'capsule-01/manifest.json');recovery=read(E/'recovery-01.json');assert recovery['complete']and recovery['pass']
assert recovery['manifestSha256']==sha(E/'capsule-01/manifest.json')and recovery['inventorySha256']==sha(E/'capsule-01/inventory.json')
protected=read(E/'phase6-start-state.json')['rows'];assert len(protected)==75
status={x[3:]:x[:2]for x in subprocess.check_output(['git','status','--porcelain=v1','--untracked-files=all'],cwd=R,text=True).splitlines()}
for x in protected:
 assert sha(R/x['path'])==x['sha256']and status.get(x['path'])==x['status'],x['path']
 assert x['path']not in idx,x['path']
assert not any('/phase6/'in n for n in idx)
assert [n for n in idx if '/context-'in n]==['selfhost/build/phase19/context-row-source-05/first-element-only.patch']
assert not any(set(Path(n).parts)&{'.git','.ssh','.aws','.kube'}for n in idx)
root=read(E/'root-release-freeze.json');frozen={}
for x in root['files']+root['inputs']:
 p=Path(x['file']);n=str(p.relative_to(R));assert sha(p)==x['sha256'],n;assert n in idx and idx[n]['sha256']==x['sha256'],n;frozen[n]=x['sha256']
adapter=read(E/'root-freeze.json')
for x in adapter['inputs']:assert sha(R/x['path'])==x['sha256'],x['path']
prior=read(R/'implementation/phase19/instance-evidence/capsule-01/inventory.json');pidx={x['path']:x for x in prior['members']};historical=[]
audit=read(R/'selfhost/build/phase20/declaration-integration-audit-03/report.json')
names=[str(Path(x['file']).relative_to(R))for x in audit['inputs']if '/build/phase19/'in x['file']]
names+=['selfhost/build/phase19/instance-build-03/equality/api.mjs','selfhost/build/phase19/instance-build-03/attempt.json']
for n in sorted(set(names)):
 assert n in pidx and sha(R/n)==pidx[n]['sha256'],n;historical.append({'path':n,'sha256':pidx[n]['sha256'],'externalPriorCapsuleMatch':True})
expected=read(E/'source-delta.json');assert recovery['sourceReconstruction']['files']==expected['members']==214
assert recovery['sourceReconstruction']['baselineCommit']==expected['baselineCommit']=='fd9e8b28c906dff13471fab9afc6975fd5574edd'
assert sha(R/'selfhost/dist/typed-api.mjs')==inv['finalApiSha256']=='40c8f7f3b7cd0e96aef57d7d574ebfd85607cd4e096909d083b450b4d973362c'
assert sha(R/'selfhost/src/front/declarations.bend')==idx[inv['finalSource']+'/src/front/declarations.bend']['sha256']
receipt={'kind':'phase20-post-capture-identity-audit','complete':True,'pass':True,'protectedPhase6':{'count':75,'hashesAndStatusesUnchanged':True,'payloadExcluded':True},'rootFrozenInputs':len(frozen),'allRootFrozenInputsCapturedUnchanged':True,'historicalComparisonIdentities':historical,'onlyContextualPayload':'context-row-source-05/first-element-only.patch','sourceReconstructed':214,'oneFileDelta':expected['changedFiles'],'manifestSha256':sha(E/'capsule-01/manifest.json'),'inventorySha256':sha(E/'capsule-01/inventory.json'),'limitations':'Bounded identity/path audit, not a comprehensive secret scanner or rerun of compiler conformance.','inputs':[ident(Path(__file__)),ident(E/'phase6-start-state.json'),ident(E/'root-release-freeze.json'),ident(E/'recovery-01.json'),ident(R/'implementation/phase19/instance-evidence/capsule-01/inventory.json')]}
out.write_text(json.dumps(receipt,indent=2)+'\n');print(json.dumps({'pass':True,'protected':75,'frozenInputs':len(frozen),'historical':len(historical),'report':str(out)}))
