# Closed Phase17 evidence preservation

Prospective plan. No inventory, capture or recovery has run. Root must explicitly
freeze the closed release, CLI results and documentation before capture.
Phase18 code, tools, designs, reports and build roots are excluded entirely.

## Selected topics

1. `find-worker-*` and `find-demand-*`: the complete released source/build,
   original demand controls, every final gate, matrix inputs and timings,
   promotion failures/success, installed CLI smoke and their consumed tools.
2. `group-*`: the isolated grouping ablation, unbuilt rejected source01,
   source02/checked derivative, failed control preparations, original paired
   observations, structural controls and independent audit. Preserve its raw
   nonconformant oracle verdict; this candidate is not installed.
3. `instance-*`: failed preparation, original and corrected nested witnesses,
   paired observations, public memo controls, source census and reports.
   Preserve the nondiscriminating first nested witness and both measured gaps.

Include all closed current Phase17 tools and direct Phase17 design/report files.
Include exact custom fixture sibling trees explicitly referenced by selected
case records, with a dependency review after preparation. Any dependency under
an excluded Phase18 root is an error requiring review, not an automatic expansion.
Do not include unrestricted earlier experiment directories or Phase6 tooling.

The already durable `implementation/phase17/profile-evidence` archive is an
external prerequisite bound by its manifest/archive SHA. The two raw
`compact-profile-*` directories are excluded from recapture. The prior Phase16
compact capsule and its declared historical prerequisites remain separate; no
claim is made that this bundle repairs their recorded preservation omissions.
No original artifacts are deleted.

## Reused machinery

The new collector is a copy of the verified Phase16 collector with only phase
paths/labels, the patch filename and explicit excluded-tree rejection changed.
[The exact adaptation](collector-adaptation.patch) and [identity record](adaptation.json)
are retained. Archive splitting, regular/link identity checks, deterministic
encoding and fixed-commit patch generation are unchanged. Topic parts target
64 MB uncompressed payload and must remain below 99,000,000 compressed bytes.

Use the **unchanged** Phase16 `compact-recover.py`, SHA
`654bcf4435c7b02d329299aa3f4a71aed46c122b556ecd06bfbccece15972234`.
Its nine already-passing policy controls remain applicable; no path policy or
recovery behavior has changed, so they need not be repeated. Its historical
`phase16` report-kind label identifies the reused format, not the recovered
source baseline. Manifest/inventory identities and recovery results determine
which capsule was verified.

Independently verify every archive hash, exact member set, bytes, type and mode,
then reconstruct all **214 final project members** from committed Phase16
`0b51d965e2638048b5526b351047daae0c61ed7c` plus the saved source patch. Recovery
uses fresh directories and no working-tree source. Keep final outcome metadata
outside captured inputs to avoid self-reference.

## Freeze and execution sequence

Root provides `implementation/phase17/evidence/root-freeze.json` with
`authorized:true`, `allProducersClosed:true`, final attempt
`selfhost/build/phase17/find-worker-build-01`, API
`9b20de5032e306a0b7ee2686a1cc79452f81fcb282ff6419a0d1ad5c4b5716b6`,
release commit and exact frozen input hashes. Its `additionalFiles` selects
installed `selfhost/dist` and current root/compiler/architecture documentation,
STEERING and ledger. Include only explicit paths whose producers are closed.

After freeze: prepare a fresh exact inventory and fixed-baseline patch; review
all selected/excluded roots, fixture expansions and part sizes; capture without
editing inputs; run unchanged independent recovery; write a separate result/index
and report producer closure. Preserve any failed preparation or capture verbatim
under distinct names. Root reviews, commits and handles publication.
