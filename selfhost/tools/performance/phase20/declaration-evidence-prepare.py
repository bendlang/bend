"""Freeze a scoped Phase20 preservation proposal; no archive or extraction work."""
from pathlib import Path
import json,hashlib,subprocess,shutil,difflib
R=Path(__file__).resolve().parents[4];E=R/'implementation/phase20/declaration-evidence';E.mkdir()
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
ident=lambda p:{'path':p.relative_to(R).as_posix(),'sha256':sha(p),'bytes':p.stat().st_size}
write=lambda p,x:p.write_text(json.dumps(x,indent=2)+'\n')
releaseFreeze=R/'selfhost/build/phase20/declaration-release-freeze-01.json'
assert sha(releaseFreeze)=='128aa964100a84549c20ae91f9daf8d7b39e17f6cb294a04902436c54a8b956b'
root=json.loads(releaseFreeze.read_text());assert root['allProducersClosed']
for x in root['files']+root['inputs']:assert sha(Path(x['file']))==x['sha256'],x['file']
shutil.copy2(releaseFreeze,E/'root-release-freeze.json')
releasePaths=json.loads(Path('/tmp/phase20-release-commit-paths.json').read_text());assert len(releasePaths)==60
write(E/'release-paths.json',releasePaths)
protected=json.loads((R/'implementation/phase19/instance-evidence/phase6-start-state.json').read_text())['unrelatedPhase6'];assert len(protected)==75
status={x[3:]:x[:2]for x in subprocess.check_output(['git','status','--porcelain=v1','--untracked-files=all'],cwd=R,text=True).splitlines()}
for x in protected:assert sha(R/x['path'])==x['sha256']and status.get(x['path'])==x['status'],x['path']
write(E/'phase6-start-state.json',{'kind':'phase20-protected-phase6-identities','count':75,'unchangedFrom':'implementation/phase19/instance-evidence/phase6-start-state.json','rows':protected})
parent=R/'selfhost/tools/performance/phase19/instance-preserve.py';target=R/'selfhost/tools/performance/phase20/declaration-preserve.py';before=parent.read_text();after=before
replacements={
 'implementation/phase19/instance-evidence':'implementation/phase20/declaration-evidence',
 'installed-live-checker-release':'installed-declaration-checkpoint-release',
 'Explicit installed live checker release freeze required':'Explicit installed declaration checkpoint release freeze required',
 'phase19-instance-scoped-inventory':'phase20-declaration-scoped-inventory',
 'Selected closed Phase19 live checker release and its checker experiments/gates only; active contextual parser work and previously preserved prefix originals remain outside this capsule.':'Closed Phase20 declaration checkpoint release, retained source01-04 preparations and scoped/broad/execution/cost gates; private contextual parser payloads and prior release originals are external.',
 'excludedPhase19Roots':'excludedPhase20Roots',
 'phase19-instance-scoped-capture':'phase20-declaration-scoped-capture',
 'Usage: instance-preserve.py':'Usage: declaration-preserve.py',
}
for a,b in replacements.items():assert a in after,a;after=after.replace(a,b)
assert not target.exists();target.write_text(after);target.chmod(parent.stat().st_mode&0o777)
(E/'collector-adaptation.patch').write_text(''.join(difflib.unified_diff(before.splitlines(True),after.splitlines(True),fromfile=str(parent.relative_to(R)),tofile=str(target.relative_to(R)))))
recover=R/'selfhost/tools/performance/phase16/compact-recover.py'
write(E/'adaptation.json',{'kind':'phase20-literal-only-collector-adaptation','parent':ident(parent),'collector':ident(target),'unchangedRecovery':ident(recover),'replacements':replacements,'algorithmChanges':False})
roots=sorted((R/'selfhost/build/phase20').iterdir());trees={k:[]for k in ['final','experiments']}
for p in roots:
 assert p.name.startswith(('declaration-','import-diagnostic-')),p
 trees['experiments'if p.name.startswith('import-diagnostic-')else'final'].append(str(p.relative_to(R)))
extra=set(releasePaths)
extra.update(['selfhost/dist/base.bend','selfhost/dist/release-lineage/equality.mjs','selfhost/cli.mjs',
 'implementation/phase19/instance-evidence/preservation.json','implementation/phase19/instance-evidence/capsule-01/manifest.json',
 'selfhost/tools/performance/phase19/instance-preserve.py','selfhost/tools/performance/phase16/compact-recover.py',
 'selfhost/tools/performance/phase16/spans-context-controls-v2.mjs','selfhost/tools/performance/phase16/spans-context-host-controls-v2.mjs',
 'selfhost/tools/performance/phase16/check-matrix-v2.mjs','selfhost/tools/performance/phase16/frontend-gate-v2.mjs',
 'selfhost/tools/performance/phase19/instance-paired.mjs','selfhost/tools/performance/phase15/release-smoke.mjs','selfhost/tools/performance/phase15/release-smoke-launch.mjs',
 'selfhost/tools/conformance/compare-artifacts.mjs','selfhost/tools/conformance/inventory.mjs','selfhost/tools/conformance/persistent-probe.mjs',
 'selfhost/tools/development/workflow.mjs','selfhost/tools/development/equality.mjs','selfhost/tools/development/process.mjs','selfhost/tools/development/release.mjs',
 'implementation/phase8/conformance-harness-evidence/frontend-triage.mjs',
 'selfhost/build/phase19/context-row-source-05/first-element-only.patch',
 str(Path(__file__).relative_to(R)),str(target.relative_to(R))])
extra.update(str((E/n).relative_to(R))for n in ['root-release-freeze.json','release-paths.json','phase6-start-state.json','adaptation.json','collector-adaptation.patch'])
baseline='fd9e8b28c906dff13471fab9afc6975fd5574edd';commit=subprocess.check_output(['git','rev-parse','c385d39'],cwd=R,text=True).strip()
source=R/'selfhost/build/phase20/import-diagnostic-source-04/project';members={str(p.relative_to(source)):sha(p)for p in source.rglob('*')if p.is_file()};assert len(members)==214
changed=[]
for n,h in members.items():
 b=subprocess.check_output(['git','show',baseline+':selfhost/'+n],cwd=R)
 if hashlib.sha256(b).hexdigest()!=h:changed.append(n)
assert changed==['src/front/declarations.bend'],changed
write(E/'source-delta.json',{'baselineCommit':baseline,'source':str(source.relative_to(R)),'members':214,'changedFiles':changed,'delta':{'physicalLines':17,'definitions':1,'laws':0,'types':0,'bytes':1110}});extra.add(str((E/'source-delta.json').relative_to(R)))
excluded=[str(p.relative_to(R))for p in (R/'selfhost/build/phase19').glob('context-*/project')]+[str(p.relative_to(R))for p in (R/'selfhost/build/phase19').glob('context-*/snapshot')]
excluded+=['selfhost/build/phase21','selfhost/tools/performance/phase6','selfhost/dist/release-history','selfhost/dist/selfcheck','selfhost/dist/selfhost']
plan={'kind':'phase20-declaration-evidence-selection','anchorStatus':'installed-declaration-checkpoint-release','releaseCommit':commit,'baselineCommit':baseline,'finalSource':str(source.relative_to(R)),'finalAttempt':'selfhost/build/phase20/import-diagnostic-build-04','finalApiSha256':'40c8f7f3b7cd0e96aef57d7d574ebfd85607cd4e096909d083b450b4d973362c','phaseRoot':'selfhost/build/phase20','topics':{'final':[],'experiments':[]},'extraTrees':trees,'extraFiles':{'final':sorted(extra)},'closedDocumentationDirectories':[],'excludedTrees':excluded,'excludedTopLevelReason':'Outside the exact closed Phase20 declaration release selection.','maxPartPayloadBytes':64000000,'maxArchiveBytes':99000000,
 'externalPrerequisites':[{'kind':'committed-source','commit':baseline,'scope':'Fixed prior installed release, used for independent recovery of all214 finalsource members.'},{'kind':'prior-release-capsule','path':'implementation/phase19/instance-evidence/preservation.json','manifest':'implementation/phase19/instance-evidence/capsule-01/manifest.json','scope':'Original comparison source/API, histories and Phase18/17/16 prerequisite chain; no old record is rebound to current live source.'},{'kind':'upstream-checkout','path':'selfhost/.bootstrap/upstream-phase8','commit':'b2111cf43244e65f76ddc278ee695e669f720cbf','scope':'Pinned compiler/Base/upstream fixtures; unmodified external prerequisite.'},{'kind':'toolchain','scope':'Recorded Node/Clang binaries are external; no credentials or private home configuration is included.'},{'kind':'private-contextual-experiment','scope':'Contextual projects remain outside capsule; only exact reviewed first-element-only.patch is included.'}]}
write(E/'selection-proposal.json',plan)
(E/'PLAN.md').write_text('''# Phase20 declaration release preservation

Preserve installed release c385d39, source04/build04/API40c8, and every closed
Phase20 declaration/import-diagnostic experiment. Exact roots are enumerated in
selection-proposal.json; no active-prefix wildcard expands future work. Keep
source02/source03 semicolon counterexamples, failed integration audits01/02,
zero-copy failed promotions01/02, raw group196 false status, and neutral matrix
samples. Reports remain immutable and keep their original limitations.

Use the literal-only instance-preserve adaptation and unchanged compact-recover.
Prepare inventory first, review membership, largest member, safety and exact
one-file delta; capture only after independent review. Recovery checks every
archived byte/mode/link and reconstructs all214 source members from fixed commit
fd9e8b28c906dff13471fab9afc6975fd5574edd plus the recorded patch, without working
tree source. Prior release and pinned TypeScript remain declared prerequisites.

The protected75 Phase6 files are identity-only and must keep both hashes and git
status. Private contextual projects are excluded; only their reviewed guard patch
is selected. Structured case records may add required fixture sibling trees;
review these exact additions before capture. Project source/build/test logs are
expected payload; git metadata, private home files and credentials are not.

Preparation performs no archive/extraction. Current disk is constrained; wait
for contextual preservation to release the serial window before capture/recovery.
Never overlap large extractions. Post-capture review, recovery receipts, README
and preservation summary stay outside captured inputs. No compiler jobs or live
source edits belong to this task. Root alone owns git and release documentation.
''')
inputs={str(Path(x['file']).relative_to(R)):x['sha256']for x in root['files']+root['inputs']}
for p in [E/'selection-proposal.json',E/'PLAN.md',E/'root-release-freeze.json',E/'release-paths.json',E/'phase6-start-state.json',E/'source-delta.json',E/'adaptation.json',E/'collector-adaptation.patch',target,Path(__file__),recover]:inputs[str(p.relative_to(R))]=sha(p)
write(E/'root-freeze.json',{'kind':'phase20-preservation-root-freeze-adapter','authorized':True,'authorization':'Parent explicit Phase20 preservation task; underlying release freeze retained unchanged.','allProducersClosed':True,'anchorStatus':plan['anchorStatus'],'finalAttempt':plan['finalAttempt'],'finalApiSha256':plan['finalApiSha256'],'inputs':[{'path':p,'sha256':h}for p,h in sorted(inputs.items())],'additionalFiles':[]})
print(json.dumps({'prepared':True,'ownedDirectory':str(E),'collector':str(target),'sourceMembers':214,'deltaFiles':changed,'roots':len(roots),'protected':75,'captureRun':False}))
