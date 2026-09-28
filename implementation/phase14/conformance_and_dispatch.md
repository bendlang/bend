# Phase14: conformance and source dispatch

The combined compiler is promoted. It fixes all four imported-law trust cases,
reduces exact frontend differences from **730 to 603**, and uses **8.82% less
full-source checking time** than the previous release in a fresh controlled
comparison. Pinned TypeScript remains **8.88× faster** by process time on that
workload. This remains an experimental compatibility port.

The [design](../../design/phase14/conformance_and_dispatch.md) and frozen
[experiment plans](../../experiments/phase14/) preceded the changes. Work began
on 2026-09-28 from commit d0d5878 and Phase12 API0975a4a8. Upstream remains
`b2111cf43244e65f76ddc278ee695e669f720cbf`; its sources were not edited.
The dispatch pilot finished well inside its 90-minute cap. No earlier multi-hour
budget was renewed. All 75 unrelated Phase6 files remain unchanged and unstaged.

## Changes and their causes

[Imported laws](imported-laws.md) failed because each source module was parsed
before its dependencies loaded. Omitted return types could inherit only a local
law's signature. The correction temporarily retains an alias-qualified fill's
parameter telescope and resolves it against the latest imported law during the
existing alias traversal. It preserves canonical type/name, binder lowering,
chronology and unsafe taint. Two internal markers disappear before the canonical
loader returns its book. Native, already-filled, missing, annotated and invalid
fills remain refused; the legacy name-based loader refuses unresolved markers.

Trust reporting receives the loaded declaration-event book at exactly two host
call sites. Bend selects names in source event order but resolves dependencies
from final declarations. Checking and materialization keep their existing books.
This restores first-declaration order without allowing an old bodiless law to
hide a later unsafe fill. Independent template, chronology, foreign and native
controls guard the wider trust effect; the full corpus audits every output delta.

[Diagnostic rendering](exact-differences.md) now draws a caret row from existing
checker spans. UTF-16 offsets, tabs, clipping and empty/reversed ranges have direct
reference controls. The selected family becomes exact in 71 of 78 observations;
seven earlier span-origin errors remain strict failures. Across the full corpus,
the renderer yields 71 new exact checker observations. It does not change parsing,
infer a better error span or relax the exact oracle.

[Source dispatch](source-dispatch.md) expresses six normalizer tag choices as
Boolean-parameter workers. Pinned upstream emits direct conditionals/calls,
removing intermediate choice closures, Unit values and trampoline messages.
Selected bodies and evaluation order stay unchanged. The initial normalizer
fallback allocation and nested rewrite-proof choice remain intact. This obtains
most of the earlier selector prototype's benefit with six Bend helpers and no
additional maintained JavaScript transformation. The worker chain is not emitted
as one mutually recursive loop; finite stack/history controls remain necessary.

## Controlled performance

`selfhost/build/phase14/check-matrix-01/report.json` binds the exact source,
compilers, runtime, Base, host, unchanged Phase8 worker and Node24.18.0. It checks
the same final assembled source, excluding emission. Six fresh processes run in
TS–Phase12–Phase14–Phase14–Phase12–TS order on CPU0, with 4MiB stack and 4GiB heap.
Other intentional compiler/archive jobs were closed. Each Bend image has its own
validated Base cache, primed outside timing; TypeScript checks Base. OS caches
are not flushed. Means include both samples per variant.

| Variant | Process wall | Request | Highest observed RSS |
|---|---:|---:|---:|
| Pinned TypeScript | 2.8118s | 1.7633s | 433,628KiB |
| Previous Phase12 release | 27.3956s | 26.2764s | 1,368,160KiB |
| Selected Phase14 release | 24.9781s | 23.8499s | 1,388,280KiB |

The selected release takes 8.82% less process time (1.0968× speedup) and 9.23% less
request time. Its process gap to TypeScript is 8.8834×, versus 9.7431× for Phase12
in this experiment. Peak observed RSS rises 1.47%; no memory saving is claimed.
Process wall includes startup, input verification and capture; the request wraps
the adapter probe and lazy API loading. All six samples pass the ordinary
type/trust gate and agree on unsafe-definition sets. The compiler source contains
unsafe definitions, so its expected trust refusal is retained, not relabeled as
independent proof validity.

The host differs only at the two reviewed trust-report calls; every other frozen
host file, Base and runtime must match. This is a complete release-workflow
comparison. The separate identical-host dispatch pilot records
27.4764→24.9945s, 9.03% less process time, before conformance integration.
Ratios are not multiplied or combined with earlier different-source measurements.
Two samples characterize this workload, not every compiler input or machine.

Routine development uses checked B1 plus a short paired selection, now 26 cases
with the long string first and four imported-law cases appended. The two
integration builds ran concurrently, so their elapsed times are not a controlled
development-loop speedup. No full self-emission or generated-program runtime
performance gain is claimed in this phase.

## Conformance and validation

The full candidate run uses the unchanged-pin reference inventory: 1,498 fixtures,
2,996 parse/check observations. `frontend-audit-02/report.json` classifies every
delta under the frozen integration policy and its explicit alias-boundary
addendum. Exact comparison retains paths, diagnostics and all semantic axes.

| Measure | Phase12 | Phase14 |
|---|---:|---:|
| Positive type accepts | 1,001/1,001 | 1,001/1,001 |
| Validation-negative refusals | 482/482 | 482/482 |
| Intended trust refusals, exact | 7/11 | 11/11 |
| Exact reference differences | 730 | 603 |
| Parse/check difference split | 198/532 | 194/409 |
| Unique fixtures with exact differences | 532 | 409 |
| Strict check passes/failures | 1,006/492 | 1,085/413 |

There are 127 new exact matches and zero lost exact matches. Eight improvements
are the four imported-law cases across two lanes; 71 are checker diagnostics
and 48 correct unsafe-definition lists and their diagnostic/output text.
Another 26 checker observations add only caret rows while retaining an existing
exact difference. Both `import/alias_decl.bend` observations now refuse during
parsing, restoring the reference phase while retaining a diagnostic-text gap.
Those 155 changed observations account for every delta. No unexpected semantic
change, invalid type acceptance, timeout, missing observation or input drift is
observed. The four expected later-emission errors retain their frontend type
acceptance; this alone is not their backend validation.

Additional gates retain their own scopes:

- Conformance-only and combined genuine checked builds each pass 26 maintained
  acceptance/rejection-phase cases, retaining 12 inherited exact diagnostic gaps.
- Imported-law controls cover 50 paired observations with zero semantic differences;
  all 11 original trust refusals and valid template controls are exact. The suite
  retains 18 diagnostic differences and its strict failed status. Twenty-four
  raw/cached/seeded loader variants agree byte-for-byte and contain no temporary
  markers. A separate native-law metadata witness passes.
- The renderer has 24 direct exact-reference controls and six precedence/positive
  controls. Its 71/78 strict family gate remains failed for the seven old spans.
- Dispatch passes 41 independent demand/semantic controls, a fresh 6,000-character
  string, and both saved 53/60-request histories at their original resource limits.
  Combined versus conformance-only APIs agree on all 226 paired history observations
  and every predecessor. Historical host provenance changes for all requests;
  only 1 and 7 diagnostics additionally differ in the respective old histories.
- All 16 unchanged equality-helper groups pass on the final checked parent;
  current version5 replay and authentic historical version1–4 byte replays also
  pass. Historical replays retain their own original parents.
- A 41-row paired backend gate passes with the same three known exact differences.
  It retains 37 earlier rows and adds checking, interpretation, JS and actual
  Clang16/native execution of a dependent imported-law fill returning `5n`.
- [Release validation](release-validation.md) binds the installed and relocated
  integrity/CLI checks, including execution without an upstream checkout.

The first full frontend launcher completed all observations, then failed an audit
assertion because absent raw reference fields were `undefined` while the comparison
schema represents them as `null`. That report remains failed in `frontend-01`.
The v3 audit uses the existing comparison contract, directly binds compiler,
runtime, Base, driver and adapter identities to the verified attempt, and reaudits
the same healthy vector in `frontend-audit-02`. No fixtures were rerun, observations
discarded or oracle relaxed. Earlier setup mistakes, cancelled template fixture,
strict failures and superseded tools remain in the individual reports/capsule.

## Complexity and release identity

The unchanged Phase10 counter reads the 59 ordered linked modules in both verified
attempts. Source grows from 15,130 to 15,264 physical lines and 12,916 to 13,038
nonblank lines: **+134 physical/+122 nonblank/+4,670 bytes**. It is 501,056 bytes with
1,495 definitions, 793 laws and 63 types, an increase of 11 definitions. Imported
laws add two temporary internal markers; other changes use existing representations.
This phase improves compatibility and speed rather than reducing source size.
The earlier 50%/75% simplification targets remain unachieved.

The maintained equality helper and its tests are unchanged. The host has two
argument edits (+14 bytes, no added lines); the focused selection adds four cases.
The generated API grows 6,546 bytes to 772,643 bytes. Retained research launchers,
failed attempts and evidence machinery are not compiler-source counts. Dispatch's
runnable component/control bundle is 72 lines; its complete retained research tools
are 816 lines, separately disclosed in its cost audit.

| Artifact | SHA-256 |
|---|---|
| Selected combined API | `9136be92928eda4b3b8e9c99e4e35d62504a825b458ff237c514d4e99f21206b` |
| Genuine checked B1 parent | `01d19a38560df95379b6a012016f38dad73d4ba7a1a028dba46f78fbdc5402da` |
| Assembled source | `9cb62045714ddc0490ed82a74e97eb213c5d34f583aeabfb84e5151ad5d93c4f` |
| Unchanged runtime | `1766d6d674f5c64eb481a647fe1d7bf751529d6861d4d4f4697999f005e772f0` |
| Unchanged Base | `00c751b6cd045361a80f214c9c36bd4ec637e9ec86109b194e55cd57ca63ab94` |

`combined-01` is installed; `conformance-01` API9bdcc120 is its conformance ablation.
The [release manifest](../../selfhost/dist/release.json) preserves checked provenance
and guarded version5 derivation. Phase12's default and original lineage remain
in release-history. Ordinary use has no TypeScript fallback. The
[compiler guide](../../docs/BEND-IN-BEND.md),
[architecture](../../selfhost/docs/ARCHITECTURE.md) and
[conformance notes](../../selfhost/CONFORMANCE.md) describe the supported workflow.

## Remaining work and evidence

The 603 exact differences still include parser diagnostics, originating spans,
legacy messages and rejection phases. Passing positive/negative acceptance oracles
does not establish the intended reason for every rejection. Native/GPU coverage,
general stack safety and proof-kernel validation remain separate; there is no new
self-hosted fixed point or universal compiler-soundness claim.

Next, target another measured shared diagnostic cause and profile this exact
release before broadening dispatch changes. Reuse the preserved Phase13 selector
prototype if a cheaper source formulation or substantially larger measured
opportunity appears. Do not revive rejected seed/branch transformations without
addressing their saved-history counterexamples.

The [evidence publication](evidence/README.md) binds successful and failed attempts,
raw observations, commands, consumed tools, measurements and release checks. It
requires closed producers, zero unresolved repository references and complete
byte/mode recovery with ten prerequisite capsules. Publication/recovery records
establish preservation, not additional compiler-correctness results.


## Postpublication attribution correction

The [attribution audit](exact-match-attribution.json) corrects the earlier claim
that all 119 remaining checker improvements came from rendering. They comprise
71 caret-only improvements and 48 trust-reporting improvements. Together with
eight imported-law observations, the total remains 127. The original capsule
retains the earlier wording and all original raw observations; this documentation
correction changes neither the compiler nor any validation/performance result.
