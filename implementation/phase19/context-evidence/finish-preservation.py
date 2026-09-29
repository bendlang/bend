#!/usr/bin/env python3
"""Verify closure and protected inputs, then report outside the frozen capsule."""
from pathlib import Path
import hashlib,json,stat,subprocess

ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).resolve().parent
def sha(p):
 h=hashlib.sha256()
 with Path(p).open('rb') as f:
  for b in iter(lambda:f.read(1024*1024),b''):h.update(b)
 return h.hexdigest()
def read(p):return json.loads(Path(p).read_text())
def write(name,value):
 with (HERE/name).open('x') as f:json.dump(value,f,indent=2);f.write('\n')
def rel(p):return Path(p).relative_to(ROOT).as_posix()

plan=read(HERE/'selection-proposal.json');freeze=read(HERE/'root-freeze.json')
inv=read(HERE/'capsule-01/inventory.json');manifest=read(HERE/'capsule-01/manifest.json')
recovered=read(HERE/'recovery-01.json');processes=read(HERE/'processes-01.json')
review=read(HERE/'selection-review.json')
assert processes['complete'] and processes['pass'] and len(processes['processes'])==2
assert all(p['exitCode']==0 and p['signal'] is None and not p['timeout'] for p in processes['processes'])
assert recovered['complete'] and recovered['pass'] and recovered['extraction']['allBytesAndModesVerified']
assert recovered['sourceReconstruction']['files']==215
assert recovered['sourceReconstruction']['baselineCommit']=='fddfc84b3f48aecc77c2424ddc8227cd7f63251f'
assert recovered['sourceReconstruction']['usesWorkingTreeSource'] is False
assert recovered['manifestSha256']==sha(HERE/'capsule-01/manifest.json')
assert recovered['inventorySha256']==sha(HERE/'capsule-01/inventory.json')==review['inventorySha256']
assert inv['planSha256']==sha(HERE/'selection-proposal.json') and inv['freezeSha256']==sha(HERE/'root-freeze.json')
assert len(inv['members'])==manifest['files']==7310
assert manifest['bytes']==608493045
assert len(inv['selectedRoots'])==80 and len(inv['fixtureDependencies'])==5
selected={r['path']:r for r in inv['members']}
original=read(HERE/'phase6-start-state.json')['unrelatedPhase6'];assert len(original)==75
raw=subprocess.check_output(['git','status','--porcelain=v1','--untracked-files=all','--',*[r['path'] for r in original]],cwd=ROOT).decode()
statuses={r[3:]:r[:2] for r in raw.splitlines()}
protected=[]
for r in original:
 actual={'sha256':sha(ROOT/r['path']),'status':statuses.get(r['path'],'')}
 protected.append({'path':r['path'],'before':r,'after':actual,
  'pass':actual['sha256']==r['sha256'] and actual['status']==r['status'],
  'excludedFromCapture':r['path'] not in selected})
frozen=[{'path':r['path'],'expectedSha256':r['sha256'],'actualSha256':sha(ROOT/r['path']),
 'pass':sha(ROOT/r['path'])==r['sha256']} for r in freeze['inputs']]
source=[]
for r in read(HERE/'source-membership.json')['members']:
 p=ROOT/plan['finalSource']/r['file'];s=p.lstat()
 source.append({'path':r['file'],'pass':stat.S_ISREG(s.st_mode) and stat.S_IMODE(s.st_mode)==r['mode']
  and s.st_size==r['bytes'] and sha(p)==r['sha256']})
assert all(r['pass'] and r['excludedFromCapture'] for r in protected)
assert all(r['pass'] for r in frozen+source)
assert sha(ROOT/'selfhost/tools/performance/phase16/compact-recover.py')=='654bcf4435c7b02d329299aa3f4a71aed46c122b556ecd06bfbccece15972234'
write('post-capture-audit.json',{'kind':'phase19-context-protected-and-frozen-audit','complete':True,'pass':True,
 'tool':{'path':rel(Path(__file__)),'sha256':sha(__file__)},'protected':protected,
 'frozenInputs':frozen,'sourceMembers':source,'sourceMemberCount':215,
 'selectionAndInventoryUnchanged':True,'allSelectedSourceRegularFilesUnchanged':True})

archive_bytes=sum(a['bytes'] for a in manifest['archives'])
largest=max(a['bytes'] for a in manifest['archives'])
assert largest<99000000
text=f'''# Contextual-parser stages1–4: recovered research evidence

Capture and independent recovery passed. This capsule preserves private parser
experiments and their failures; it is **not an installed compiler release**.
No source, live API or later Phase20/21 payload was changed or selected.

The capsule contains7,310 files,608,493,045 uncompressed bytes, and{len(manifest['archives'])} archives
totalling{archive_bytes:,} compressed bytes. The largest archive is{largest:,} bytes,
below99,000,000. There are no symlinks. All80 explicitly selected experiment
roots,66 original contextual tools, four reports, nine designs and the Stage4
owner receipt are retained. Five exact referenced fixture sibling directories
are included; no other experiment family is implicitly captured.

The anchor is `selfhost/build/phase19/context-row-source-05/project`, checked as
`context-row-build-05`: genuine API`caf20ce2`, selected guarded API`681bf1bc`.
All215 source members were independently reconstructed from fixed Phase17 commit
`fddfc84b3f48aecc77c2424ddc8227cd7f63251f` plus the captured patch. This covers
all214 inherited project paths and the added `src/front/contextual.bend`.
Recovery used committed bytes, never the current working-tree compiler source.

The unchanged Phase16 recovery tool verified every captured byte and mode in
fresh temporary directories, plus exact archive coverage and source membership.
Its identity remains`654bcf4435c7b02d329299aa3f4a71aed46c122b556ecd06bfbccece15972234`.
Both capture and recovery exited0; their stdout/stderr and resource affinity are
recorded in `processes-01.json`. All temporary extraction directories closed.
All75 protected Phase6 hashes/statuses and104 frozen inputs remain unchanged;
the final215 source members were checked again after recovery.

Stages1–3 retain the actual primitive/name/local ordering observations and their
explicit Unsupported boundaries. Stage4 retains all original source/seed graphs,
failure cursors/counters and the exact generated-ID failure. Its final successful
scoped-term comparison is binding-graph-checked alpha-equivalence with exact
source/state, not numeric identity: one retained generated binder is2147483653
in Bend and5 in TypeScript, with next6 on both. No free-variable or capture
difference is erased by this interpretation.

The saved196 public collection still has136 exact observations and60 differences.
Its raw report remains false/incomplete; the independent audit establishes eight
new exact matches and no lost exact matches. The original three failed verdicts
are monad check and body-comma parse/check. Unsupported private syntax is not a
conformance gain. No monad fix or full production parser migration is claimed.

All failed and superseded attempts are preserved, including the343,793,779-byte
report that repeatedly serialized Base, the underscore seed error, failed builds,
free-variable display errors, wrong direct-ID assertion, and quadratic grammar
guard. The single large report exceeds the64MB uncompressed part target and is
kept intact; the compressed archive size limit still passed.

Use `capsule-01/manifest.json` and `inventory.json` for every exact member/hash.
`selection-proposal.json`, `root-freeze.json` and `selection-review.json` record
selection and reviewed dependencies. `collector-adaptation.patch` records the
metadata-only collector adaptation; archive/path/fixture policies are unchanged.
`recovery-01.json` and `post-capture-audit.json` are the independent restoration
and protected-input receipts. `preservation.json` binds all final output paths.

External prerequisites are explicit: the recovered Phase18 parent cursor
checkpoint, Phase17/earlier evidence chain, fixed Phase17 commit, pinned upstream
`b2111cf43244e65f76ddc278ee695e669f720cbf`, and recorded executable toolchains.
Earlier source/build experiments and executable binaries are not silently
recaptured. The exact five fixture dependency trees are listed in the inventory.

To rerun independent recovery, use an unused report path:

```sh
taskset -c 3 python3 selfhost/tools/performance/phase16/compact-recover.py \\
  implementation/phase19/context-evidence/capsule-01 \\
  /tmp/context-recovery-new.json
```

Do not overwrite any frozen report or capsule. This owner performed no git
commit or push; publication remains root-owned.
'''
with (HERE/'README.md').open('x') as f:f.write(text)
files=sorted([p for p in HERE.rglob('*') if p.is_file()]+[ROOT/'selfhost/tools/performance/phase19/context-preserve.py'])
receipt={'kind':'phase19-private-contextual-experiment-preservation','complete':True,'pass':True,
 'anchorStatus':plan['anchorStatus'],'baselineCommit':plan['baselineCommit'],
 'anchor':{'source':plan['finalSource'],'attempt':plan['finalAttempt'],'genuineApiSha256':plan['genuineApiSha256'],'selectedApiSha256':plan['finalApiSha256']},
 'selectedCapsule':rel(HERE/'capsule-01'),'scope':inv['scope'],
 'capture':{'members':manifest['files'],'uncompressedBytes':manifest['bytes'],'archives':len(manifest['archives']),
 'compressedBytes':archive_bytes,'largestArchiveBytes':largest,'symlinks':0,'manifestSha256':sha(HERE/'capsule-01/manifest.json'),
 'inventorySha256':sha(HERE/'capsule-01/inventory.json')},
 'independentRecovery':recovered,'protectedPhase6':{'pass':True,'unchangedHashAndStatusCount':75,'noProtectedPayloadSelected':True},
 'frozenInputsUnchanged':104,'sourceMembersUnchanged':215,'closedRoots':80,'consumedContextTools':66,
 'fourOwnerReportsAndNineContextualDesignsSelected':True,'fixtureDependencyTrees':5,
 'installedSourceDistAndPhase20Phase21Excluded':True,'public196RawPass':False,'publicExact':136,'publicDifferences':60,
 'scopedTermContract':'Binding-graph-checked alpha-equivalence; actual generated IDs and failing exact-ID attempt retained.',
 'allOwnedArchiveRecoveryProcessesClosed':True,'compilerJobsRun':False,'gitCommitOrPublicationByOwner':False,
 'boundFiles':[{'path':rel(p),'bytes':p.stat().st_size,'sha256':sha(p)} for p in files]}
write('preservation.json',receipt)
print(json.dumps({'pass':True,'members':manifest['files'],'archives':len(manifest['archives']),
 'compressedBytes':archive_bytes,'sourceMembers':215,'preservationSha256':sha(HERE/'preservation.json'),
 'finalFiles':len(files)+1}))
