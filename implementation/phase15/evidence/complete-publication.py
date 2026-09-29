"""Finish the unchanged Phase15 capsule publication after reviewed exact-link recovery."""
import hashlib
import json
from pathlib import Path
here=Path(__file__).resolve().parent;root=here.parents[2]
def need(value,message):
 if not value:raise ValueError(message)
def read(name):return json.loads((here/name).read_text())
def identify(file):
 file=Path(file);h=hashlib.sha256()
 with file.open('rb') as f:
  for block in iter(lambda:f.read(1024*1024),b''):h.update(block)
 return {'file':str(file.relative_to(root)) if file.is_relative_to(root) else str(file),'sha256':h.hexdigest(),'bytes':file.stat().st_size}
old=read('publication-01.json');need((here/'publication.json').read_bytes()==(here/'publication-01.json').read_bytes(),'Original failed publication must be preserved verbatim before completion')
need(not old['complete'] and not old['pass'],'Initial publisher status differs')
need([(x['label'],x['exitCode']) for x in old['commands']]==[('capture',0),('verify',0),('materialize',1)],'Unexpected original command history')
freeze=read('root-freeze.json');need(freeze['rootExplicitFreeze'] and freeze['captureAuthorized'],'Root freeze missing')
for row in freeze['inputs']+[freeze['installedRelease']]:need(identify(Path(row['file']))['sha256']==row['sha256'],'Frozen producer changed: '+row['file'])
need(identify(root/'selfhost/dist/typed-api.mjs')['sha256']==freeze['selectedApiSha256'],'Installed API changed')
manifest_file=here/'capsule-01/manifest.json';manifest=json.loads(manifest_file.read_text());mid=identify(manifest_file)
need(mid['sha256']=='70b99f29a3e7adc5d5c31f2e324a79d9e93ed7a9e1e1d288220a82ecad384c26','Captured manifest changed')
archive=here/'capsule-01'/manifest['archive']['file'];aid=identify(archive)
need(aid['sha256']==manifest['archive']['sha256'] and aid['bytes']==manifest['archive']['bytes'],'Archive changed')
need(aid['bytes']<100_000_000 and mid['bytes']<100_000_000,'Oversized publication file')
reviewed=read('reviewed-recovery-02.json');recovery=read('recovery-02.json');payload=read('payload-review.json')
need(reviewed['complete'] and reviewed['pass'] and recovery['complete'] and recovery['pass'],'Recovery did not pass')
need(len(reviewed['controls'])==8 and all(x['pass'] for x in reviewed['controls']),'Policy control failure')
need(reviewed['manifest']['sha256']==mid['sha256'] and recovery['capsuleManifest']['sha256']==mid['sha256'],'Recovery capsule differs')
need(reviewed['materialization']['recoveredFiles']==len(manifest['files'])==recovery['recoveredFiles'],'Recovery coverage differs')
need(len(reviewed['materialization']['links'])==5,'Recovered link count differs')
need(payload['complete'] and payload['pass'],'Payload review did not pass')
unresolved=[r for r in manifest['references'] if r['status']=='unresolved-repository-reference'];need(not unresolved,'Unresolved repository reference')
original_readme=identify(here/'README-captured.md');captured_readme=next(r for r in manifest['files'] if r['file']=='implementation/phase15/evidence/README.md')
need(original_readme['sha256']==captured_readme['sha256'],'Original README copy differs')
need((here/'README.md').read_text().endswith((here/'README-captured.md').read_text()),'README amendment is not header-only')
report={'kind':'phase15-evidence-publication','complete':True,'pass':True,'scope':'Original capsule capture and verification plus exact-manifest reviewed recovery and independent complete byte/mode check; no recapture or compiler validation claim.',
 'freeze':identify(here/'root-freeze.json'),'initialFailedPublication':identify(here/'publication-01.json'),
 'initialFailurePreserved':'The initial materializer conservatively refused four in-tree parent-relative fixture symlinks before creating its destination; its report and logs remain unchanged.',
 'capture':old['capture'],'verification':reviewed['verification'],'materialization':reviewed['materialization'],
 'capsule':{'directory':'implementation/phase15/evidence/capsule-01','manifest':mid,'archive':aid,'summary':manifest['summary']},
 'reviewedRecovery':identify(here/'reviewed-recovery-02.json'),'recoveryCheck':identify(here/'recovery-02.json'),'policyControls':reviewed['controls'],
 'recoveryCompanion':identify(here/'recover-reviewed-symlinks.py'),'independentRecoveryTool':identify(here/'recovery-check.py'),'payloadReview':identify(here/'payload-review.json'),
 'recoveryLogs':[identify(here/name) for name in ['reviewed-recovery-02.stdout','reviewed-recovery-02.stderr','recovery-02.stdout','recovery-02.stderr']],
 'externalCapsules':manifest['externalCapsules'],'unresolvedRepositoryReferences':unresolved,
 'remainingHistoricalExternalReferences':[r for r in manifest['references'] if r['status']=='external-prerequisite'],
 'postCaptureEvidenceOnlyAmendment':{'originalReadme':original_readme,'liveReadme':identify(here/'README.md'),'recoveryInstructions':identify(here/'RECOVERY.md'),'note':'The capsule retains original README wording. Only a live README header and separately published recovery tools/records were added after capture; compiler producer files remain frozen.'},
 'frozenProducerInputsVerified':True,
 'limitations':['All eleven exact prerequisite capsules and separately tracked Phase9 profile gzip remain required.','Node, Clang, headers and host libraries remain external prerequisites; historical replay paths need adaptation.','Derived Base caches and unrelated Phase6 workspace/source-copy bytes are omitted with identities/reasons.','The unavailable historical lexical-selfhost API is context only, not a Phase15 consumed compiler.','Recovery requires the separately published exact-capsule companion; the inherited generic materializer deliberately refuses the four reviewed parent-relative links.'],
 'completionTool':identify(Path(__file__).resolve())}
(here/'publication.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({'complete':True,'pass':True,'archiveBytes':aid['bytes'],'manifestBytes':mid['bytes'],'recoveredFiles':recovery['recoveredFiles'],'symlinks':5,'policyControls':8,'archiveSha256':aid['sha256']}))
