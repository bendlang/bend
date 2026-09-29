# Phase18 checker world: stable public boundary

The final isolated Stage1 candidate preserves the historical public specialization
result while carrying the new world/count internally. All 18 raw public-result
and demand controls, 42 transport/demand controls, 22 complete parent-equivalence
observations and eight instance-name controls pass. Both known TypeScript
chronology differences remain unchanged. This is a representation checkpoint,
not a conformance fix or installed release.

The exact source is `selfhost/build/phase18/instance-world-source-06/project`,
with the cumulative parent-relative patch and manifest beside it. Genuine
`instance-world-build-06` passes checked B1, the maintained version5 derivative
and default36; two inherited strict differences remain. Its API is
`9f9648cbfc53912cd38fa78758b3409fea431f93dd285a0e911cbd373e5579ae`.
The parent is Phase17 `find-worker-source-01/project` / `find-worker-build-01`,
API `9b20de5032e306a0b7ee2686a1cc79452f81fcb282ff6419a0d1ad5c4b5716b6`.

## Boundary and implementation

The expanded internal result is now **KChecking** with term, type, uses, error,
world and consumed count. The exported `specialize_book` still returns
**KSpecialized** whose error payload is the historical four-field **KChecked**.
`sp_finish` is the sole producer of that compatibility projection. It reads the
actual internal failure; it does not invent a world or revalidate a definition.

The diagnostic renderer shares `dg_report_payload(term,error,name)` between its
internal and public callers. Two small stable-payload projections preserve the
public diagnostic's required error-before-term read order. All 71 advertised
exports remain unchanged. No host, runtime, cache, upstream or transformation
change is part of this candidate.

The original [Stage1 report](instance-world-correctness.md) describes world and
fresh-state transport. Those constraints remain: no eager bound scan, no deferred
bound resolution, no new instance effects, no source-to-checked-body replacement,
and no sibling sequencing change. Actual consumed counts remain zero. Injected
nonzero sentinels test transport only. Generic success still restores its caller
view; failures retain their actual private scope. These operations will require
separate review before introducing state effects.

## Gates and preserved failures

| Gate on source06 | Result |
| --- | --- |
| Genuine checked B1, maintained derivative, default36 | Pass, two inherited strict differences |
| Raw KSpecialized values, historical KChecked4 inputs, public field demand | 18/18 pass |
| Internal world/count, diagnostic translations, generic scope, demanded and unused fields | 42/42 pass |
| Frozen paired chronology observations against exact parent | 22/22 complete records unchanged |
| Public ABI2 materialized instance names against TS and explicit expectations | 8/8 exact |

The 22 observation comparison checks the entire candidate and reference records,
not only acceptance. Its two unchanged strict gaps are
`p17-instance/instance-before-type` and `p17-nested/local-before-instance`.
Eight whole-program/annotation comparisons are included within the direct37
subset and reuse the memo8 fixtures; these counts are not unique corpus coverage.
Private helpers are reached only through separate named probe extensions whose
original production bytes are verified as an exact prefix. Their identities are
distinct from the unmodified production API. Public18 uses no probe extension.

Source03 exposed its six-field internal result through raw KSpecialized, despite
passing the narrower DResult/CLI controls. Source04 restored the payload shape
and passed genuine checking, but its frozen public gate passed 17/18: nested
destructuring demanded term before error. Source05 attempted an explicit earlier
error binding; pinned parsing refused a later match of the already-used binder,
so no API was generated. Source06 uses separate match scopes in the projections
and passes the unchanged oracle. All attempts, failed reports and consumed tools
remain retained. Earlier source01 bootstrap and source02 transport-review findings
remain documented in the original checkpoint.

The public contract covers immutable Bend values, absence of newly demanded unused
fields, and first-failure order. The shared renderer may reuse an immutable error
instead of rereading it on a fallback branch. Equivalence to arbitrary stateful
JavaScript getters is explicitly outside this contract.

## Size and cost

Using only exact `src/compiler.json` membership, the candidate has **16,460 physical
lines, 14,042 nonblank lines, 585,764 bytes, 59 modules, 1,673 definitions, 775 laws
and 69 types**. Relative to the exact Phase17 parent this is **+107 physical /
+88 nonblank lines, +4,442 bytes, +16 definitions and +3 types**, with no module
or law removal. Five Bend files change: kernel, specializer, annotation,
diagnostic trace and diagnostic production.

Source-preparation manifests count all copied Bend files, including unchanged
noncompiled files; their larger totals are not the compiler denominator. Their
delta agrees exactly with this production-module count. The stable boundary
adds 20 physical lines, 848 bytes, three definitions and one type beyond source03.
There is no achieved source-complexity reduction: the world and Known/Deferred
availability concepts coexist with the original specializer. KChecking versus
stable KChecked is an explicit internal/public distinction, not another checker.

The root-owned [cost screening](instance-world-cost.md) measured **source03 only**:
11.7103 s parent versus 11.6839 s candidate, request time +0.39%, peak RSS +0.42%.
That is essentially neutral within the prospective 5% screening threshold, not a
speedup. The final source06 boundary adapter has no controlled timing result.
No broad conformance, backend, fixed-point, generated-code speed or installation
claim follows from these focused gates.

[Machine evidence](instance-world-public-boundary.json) binds the reports,
complete vectors, source changes, retained failures and exact module count.
The next work is a separately reviewed design for one authoritative live-instance
checking order, retaining source bodies and current public shapes.
