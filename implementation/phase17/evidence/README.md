# Phase17 release and experiment preservation

Local capture and independent recovery pass for release
`fddfc84b3f48aecc77c2424ddc8227cd7f63251f`, installed lookup API
`9b20de5032e306a0b7ee2686a1cc79452f81fcb282ff6419a0d1ad5c4b5716b6`.
See [the release report](../find-worker.md) for measured speed, correctness and
remaining gaps. This directory does not assert remote publication.

[Inventory02](capsule-02/inventory.json) contains **4,446 members**: 4,445 regular
files and one fixture link, totaling **200,395,972 uncompressed bytes**.
[Five archive parts](capsule-02/manifest.json) total **24,624,606 compressed bytes**.
Every part is below the 99,000,000-byte guard.

| Topic | Members | Parts | Compressed bytes |
| --- | ---: | ---: | ---: |
| final | 2,999 | 3 | 16,860,303 |
| group | 1,335 | 1 | 6,269,599 |
| instance | 112 | 1 | 1,494,704 |

The final topic retains the source/build, original demand and integration gates,
timing matrix, both promotion attempts, installed/relocated CLI checks, installed
distribution, closed Phase17 tools and current documentation. Group evidence
retains rejected unbuilt source01, source02 and all failed control preparations,
raw nonconformant verdicts and structural/audit results. Instance evidence retains
failed preparation, nondiscriminating and corrected witnesses, paired differences,
memo controls and source census. Neither semantic research candidate is promoted
by its inclusion here.

## Scope and exclusions

[Root freeze](root-freeze.json) binds all selected producers. [Selection review](selection-review.json)
records seven exact fixture sibling trees. Preparation01 missed the final source
count because its filename did not match the topic prefixes. Its original
[inventory](capsule-01/inventory.json), [consumed selection](capsule-01/consumed-selection-proposal.json)
and [review](capsule-01/prepare-review.json) remain unchanged; root authorized the
exact counts file, then fresh preparation02 was selected. Preparation01 was never
compressed or passed off as the final capture.

All active Phase18 build/tool/design/report roots are explicitly refused.
The only two excluded Phase17 roots are `compact-profile-01` and
`compact-profile-02`, already preserved by the separate
[profile manifest](../profile-evidence/manifest.json) and archive. Historical
Phase16/earlier references remain subject to the
[previous capsule's prerequisites and omissions](../../phase16/compact-evidence/README.md).
Pinned upstream `b2111cf43244e65f76ddc278ee695e669f720cbf` and recorded Node/Clang
executables remain external. This is a bounded selection, not a claim that every
historical path named by its reports is self-contained. No original files were
deleted.

The [protected-file audit](phase6-audit.json) verifies all **75 Phase6 hashes and
git statuses unchanged**. Its [original metadata binding](phase6-start-state.json)
is retained separately; no unrelated Phase6 source/tool payload was copied.

## Recovery

[Independent recovery](recovery-01.json) verifies every archive/member hash,
exact membership, type and mode, including the one selected relative link.
It also reconstructs all **214 final project files** from committed Phase16
`0b51d965e2638048b5526b351047daae0c61ed7c` plus
[the saved patch](capsule-02/phase16-to-final.patch), matching every byte/mode and
the exact final membership without reading working-tree source.

Run from the repository root with Python3, Git and that baseline commit present;
choose a new output report path:

```sh
python3 selfhost/tools/performance/phase16/compact-recover.py \
  implementation/phase17/evidence/capsule-02 \
  /tmp/phase17-independent-recovery.json
```

All five parts, manifest, inventory and patch must be present. The verifier uses
fresh temporary roots and removes them after verification. Recovery code is
unchanged SHA `654bcf4435c7b02d329299aa3f4a71aed46c122b556ecd06bfbccece15972234`;
its nine existing policy controls were not rerun. Its historical `phase16` report
kind is a format label; the bound inventory and explicit Phase16 baseline above
identify this Phase17 recovery. [Collector changes](collector-adaptation.patch)
are limited to phase paths/labels, patch filename and explicit Phase18 exclusion.

The immutable capture manifest retains `recoveryPending:true` from capture time;
the separate successful recovery record completes it. This README, review,
protected-file audit and final receipt are outcome metadata outside archive inputs,
avoiding self-reference. Root handles evidence commit/publication separately.
