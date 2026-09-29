"""Close a recovered immutable Phase20 capsule and list exact owner outputs."""
from pathlib import Path
import json,hashlib
R=Path(__file__).resolve().parents[4];E=R/'implementation/phase20/declaration-evidence'
read=lambda p:json.loads(p.read_text());sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
ident=lambda p:{'path':str(p.relative_to(R)),'sha256':sha(p),'bytes':p.stat().st_size}
manifest=read(E/'capsule-01/manifest.json');inventory=read(E/'capsule-01/inventory.json');recovery=read(E/'recovery-01.json');audit=read(E/'post-capture-audit.json');plan=read(E/'selection-proposal.json')
assert manifest['complete']and manifest['captured']and recovery['pass']and audit['pass']
assert recovery['manifestSha256']==sha(E/'capsule-01/manifest.json')
assert recovery['inventorySha256']==sha(E/'capsule-01/inventory.json')
assert recovery['sourceReconstruction']['files']==214
review=read(E/'selection-review.json');assert review['complete']and review['pass']
for name in ['declaration-integration-audit-01','declaration-integration-audit-02','declaration-promotion-01','declaration-promotion-02','declaration-group196-01']:
 j=read(R/'selfhost/build/phase20'/name/'report.json');assert not j['pass']
 if name.startswith('declaration-promotion'):assert j['copies']==[]
archives=manifest['archives'];compressed=sum(x['bytes']for x in archives);largest=max(x['bytes']for x in archives);assert largest<99000000
readme=E/'README.md';assert not readme.exists();readme.write_text(f'''# Recovered Phase20 declaration release evidence

This capsule preserves the installed declaration checkpoint release
`{plan['releaseCommit']}`, checked source04/build04/API40c8. The final release source
and all earlier Phase20 attempts are included, including rejected source02/source03,
the independent semicolon counterexamples, failed audits/promotions and the raw
grouped runner's false/incomplete result. The neutral performance matrix is kept
with its original samples; this capsule makes no additional speed claim.

Capture contains {manifest['files']} members in {len(archives)} archives,
{compressed:,} compressed bytes ({manifest['bytes']:,} payload bytes).
Largest archive: {largest:,} bytes. Exact membership, modes and hashes are in
`capsule-01/inventory.json` and `capsule-01/manifest.json`. Three fixture symlinks
remain relative to captured regular files. No Phase6 payload, git metadata or
private contextual project is included; the exact guard patch is the sole
contextual input. The frozen release paths include the prospective
`design/phase21/group-boundaries.md` document; no Phase21 build/tool payload is
included. The protected75 identities and git statuses remain unchanged.

Independent unchanged compact-recover restored every member and reconstructed
all214 source files from fixed prior release
`fd9e8b28c906dff13471fab9afc6975fd5574edd` plus `prefix-to-anchor.patch`, without using
working-tree source. Only `src/front/declarations.bend` differs from that baseline.
The capture manifest's recoveryPending field describes capture-time state; the
completed independent result is `recovery-01.json` and `preservation.json`.

To verify in a checkout containing the declared prior commit and unchanged tool:

```sh
python3 selfhost/tools/performance/phase16/compact-recover.py \\
  implementation/phase20/declaration-evidence/capsule-01 \\
  /tmp/phase20-independent-recovery.json
```

Use a new output path. Recovery uses temporary extraction directories and removes
them on completion. The prior Phase19 capsule, pinned TypeScript checkout and
recorded Node/Clang toolchains remain explicit external prerequisites. This is a
preservation/reconstruction check; it does not rerun compiler conformance.

Selection review, post-capture audit and final receipts are outside the immutable
capture inputs. Root owns git publication; no network upload was performed by
the preservation owner.
''')
ownTools=[R/'selfhost/tools/performance/phase20'/n for n in ['declaration-evidence-prepare.py','declaration-preserve.py','declaration-evidence-close.py']]
report={'kind':'phase20-installed-declaration-evidence-preservation','complete':True,'pass':True,'releaseCommit':plan['releaseCommit'],'anchorStatus':plan['anchorStatus'],'source':plan['finalSource'],'attempt':plan['finalAttempt'],'apiSha256':plan['finalApiSha256'],'selectedCapsule':str((E/'capsule-01').relative_to(R)),
 'capture':{'members':manifest['files'],'uncompressedBytes':manifest['bytes'],'archives':len(archives),'compressedBytes':compressed,'largestArchiveBytes':largest,'symlinks':recovery['extraction']['symlinks'],'manifestSha256':sha(E/'capsule-01/manifest.json'),'inventorySha256':sha(E/'capsule-01/inventory.json')},'independentRecovery':recovery,'protectedPhase6':audit['protectedPhase6'],'allRootFrozenInputsCapturedUnchanged':True,'historicalComparisonIdentities':audit['historicalComparisonIdentities'],'retainedFailures':['Source02 new semicolon false acceptance and superseded source03','Integration audit01/02 incomplete false outputs','Promotion01/02 failed before any copies','Grouped raw incomplete/false result with remaining strict differences'],'cost':'Neutral controlled matrix preserved, no new speedup claim.','scope':inventory['scope'],'remotePublication':'Not performed; root owns commits and publication.','allOwnedCompilerArchiveRecoveryProcessesClosed':True,
 'boundFiles':[ident(p)for p in sorted(E.rglob('*'))if p.is_file()]+[ident(p)for p in ownTools]}
target=E/'preservation.json';assert not target.exists();target.write_text(json.dumps(report,indent=2)+'\n')
owned=E/'owned-paths.json';assert not owned.exists();owned.write_text(json.dumps({'kind':'phase20-preservation-owned-paths','paths':sorted([str(p.relative_to(R))for p in E.rglob('*')if p.is_file()]+[str(p.relative_to(R))for p in ownTools]+[str(owned.relative_to(R))])},indent=2)+'\n')
print(json.dumps({'complete':True,'pass':True,'receipt':ident(target),'ownedPaths':ident(owned),'capture':report['capture']}))
