# Phase15: parser conformance and measured checking speed

The combined compiler is installed under the frozen
[design](../../design/phase15/parser_conformance_and_speed.md). The selected release is `combined-02`,
with a separate `conformance-02` control. The upstream pin remains
`b2111cf43244e65f76ddc278ee695e669f720cbf`; its TypeScript sources are unchanged.
Work began from commit `bb25185` on 2026-09-28 and continued past midnight UTC.
No previous multi-hour budget was renewed. The bounded speed pilot finished
inside the 90-minute feasibility cap; it did not become another broad rewrite.

## Changes and causes

[Parser/load behavior](parser-load.md) corrects the ten remaining corpus fixtures
whose differences included behavior axes. Malformed erased binders now require a
valid name. Local imports use the pinned plain-segment grammar before filesystem
resolution. Import nodes retain the original path token's line and code-point
column, allowing missing-file and cycle diagnostics to use the caller's source.
The ordinary host catches only an imported ENOENT or its private cycle signal;
missing entry files and other IO failures retain their original handling.

Import error order required an additional experiment. Upstream loads earlier
imports before parsing a module's body. Simply deferring a body's parse error
changed which error won in a cyclic graph with two malformed bodies. That first
candidate was rejected. The final host distinguishes active canonical IO paths
from completed visits, stops reentry at the closing edge, and delegates diagnostic
text and rendering to Bend. Completed physical aliases remain valid. Supplied-
source Bend loading retains its own graph validation. All 16 expanded cycle,
alias, diamond and cycle-before-missing observations now match pinned TypeScript.

[Parser carets](parser-carets.md) reuse the existing diagnostic snippet renderer.
The parser still finds tokens using code-point columns and retains conservative
legacy fallbacks; a separate UTF-16 offset supplies the shared zero-width span.
This removes four definitions and three laws: 35 physical lines and 1,017 bytes.
The isolated 132-observation family becomes exactly compatible. Twenty direct
parser controls preserve rendering/book/import/error-order invariants, with 12
exact matches and eight explicitly inherited diagnostic gaps. All 24 shared
renderer boundary controls pass.

Sharing that renderer changes the standalone frontend's module closure. Its
maintained component check now includes core pretty-printing and diagnostic
model/rendering, while explicitly excluding `src/check/` and
`src/diagnostic/{trace,produce,frontend}.bend`. The genuine 25-module component and all three
raw/traced/seeded loader APIs pass. The architecture documentation records this
dependency instead of retaining the old claim of no diagnostic dependencies.

[Lookup workers](checker-speed.md) follow a fresh profile of the actual Phase14
release. Of 2,551 samples, lookup owns 4.37%, GC 14.10% and the trampoline loop
12.21%; these shares are not recoverable-speed forecasts. Two Boolean-parameter
workers replace intermediate choices in ordinary-list lookup. The cache marker
still wins before the ordinary name test, duplicate names remain first-match-
wins, and demand/read order stays intact. Pinned upstream emits a three-state
mutual-tail loop, duplicated at its generated entries. No index representation,
runtime, maintained JS transformation or public ABI changes are needed.

The isolated speed candidate passes 68 tailored demand/semantic controls, 5,769
persistent-index assertions, 26 focused cases and exact saved request histories.
On the 64-definitions-per-module operation witness it removes 8,771 selected
closures, 17,093 Unit objects and 17,029 messages/dispatches. Load counts remain
unchanged. These counters identify removed work; they are not timing estimates.
Its controlled ABBA pilot reduces mean process wall from 25.0728 to 24.1980 s
(3.49%) and request time by 4.11%, at a cost of two definitions, 22 lines and
332 source bytes. Two samples per image support this bounded result, not a
universal speedup. Generated user-program runtime speed is not measured here.

## Controlled final comparison

The final matrix (`selfhost/build/phase15/check-matrix-01/report.json`) checks
identical final source, excluding emission. It uses the unchanged Phase8 worker,
serial fresh processes in TS–Phase14–Phase15–Phase15–Phase14–TS order, CPU0,
4 MiB stack and 4 GiB heap. Each Bend image has a separately validated Base
cache prepared outside timing; TypeScript checks Base. OS caches are not flushed.
All intentional compiler/archive jobs were closed from 00:30:23 to 00:32:15 UTC.
The complete host delta is pinned by reviewed before/after hashes and a patch;
every other frozen host file, Base and runtime agrees.

| Variant | Mean process wall | Mean request | Highest observed RSS |
|---|---:|---:|---:|
| Pinned TypeScript | 2.8858 s | 1.8265 s | 444,628 KiB |
| Phase14 release | 25.0780 s | 23.9151 s | 1,394,772 KiB |
| Phase15 release | 24.1023 s | 22.9768 s | 1,362,796 KiB |

Phase15 takes **3.89% less process time** (1.0405× speedup) and **3.92% less
request time**. The gap to TypeScript is **8.3520×**, versus 8.6901× for Phase14
in this same experiment. Each mean uses two samples. Observed peak RSS is lower,
but this is not a general memory-saving claim. Process wall includes startup,
hashing and capture; the request wraps the adapter probe and lazy API loading.

Every sample passes the ordinary type/trust and execution/input-health gates;
unsafe-definition sets agree. The compiler's expected unsafe-definition trust
refusal remains an ordinary result, not a proof-validity claim. The matrix
compares complete release workflows with the explicit host correction. The
isolated identical-host lookup pilot separately shows 3.49% less process time;
these percentages are not multiplied or combined with earlier different-source
ratios. No generated-program runtime speedup is claimed.

## Conformance and release gates

Both corrected checked builds pass all 36 maintained focused cases, retaining
11 exact diagnostic differences. The selection keeps the long string first,
the four earlier imported-law trust cases, six newly exact upstream checks and
four separate illegal-import-path witnesses with explicit refusal-at-parse
oracles. The latter preserve program lines and replace only their copied `#|`
oracle lines with blanks. Original upstream fixtures and strict diagnostics are
unchanged. The full inventory independently checks all ten original fixtures.

The full gate completes all 1,498 fixtures and 2,996 parse/check observations.
All 1,001 positives accept, all 482 validation negatives refuse, and all 11
intended trust refusals remain exact. No invalid acceptance, timeout, unresolved
observation, lost exact match or unexpected delta is observed. The four expected
later-emission failures retain frontend type acceptance; backend validation is
separate.

| Measure | Phase14 | Phase15 |
|---|---:|---:|
| Exact reference differences | 603 | 459 |
| Parse / check difference split | 194 / 409 | 122 / 337 |
| Unique fixtures with exact differences | 409 | 337 |
| Strict check passes / failures | 1,085 / 413 | 1,157 / 341 |
| Exact intended trust refusals | 11 / 11 | 11 / 11 |

There are 144 new exact matches and zero lost matches. Another 66 observations
add only parser caret rows while retaining existing diagnostic gaps; eight
illegal-import-path observations restore reference behavior while retaining
observed-token wording differences. Those 218 changed observations account for
every delta under the frozen policy. Exact per-cause attribution and remaining
axes are recorded in [the independent audit](exact-differences.md). It attributes
132 new matches to parser carets, ten to missing-import context, and two to the
binder fix plus carets. All measured primitive result axes agree on this corpus;
all 459 remaining differences include diagnostic text. No lookup or cycle benefit
is falsely attributed to the fixed corpus rows.

The 41-row paired backend gate passes with the same three known exact differences.
It includes 20 actual native program executions across reference and candidate;
the dependent imported-law program still returns `5n` through interpretation,
JavaScript and native execution. All 42 installed/relocated CLI checks pass, including six interpreter, six JS
and six actual native program executions. Integrity and fixture bytes stay stable;
relocation supplies no upstream checkout.

The final helper gate passes all 16 maintained groups and five authentic v1–v5
byte replays. Conformance-only and optimized candidates agree on both fresh
long-string probes and all 226 paired observations from the exact 53/60 histories,
including predecessors, under the original resource and recycling policy.
Historical host/diagnostic differences remain explicit. These finite histories
do not establish general stack safety. See [integration validation](integration-validation.md)
and [release validation](release-validation.md) for their final scoped evidence.

## Complexity and artifact identity

The linked source now has **15,288 physical / 13,059 nonblank lines**, 503,048 bytes,
1,499 definitions, 790 laws and 63 types across the same 59 modules. Relative to
Phase14 this is +24 physical lines, +21 nonblank lines, +1,992 bytes, +4 definitions
and −3 laws. Sharing a formatter removes one duplicate implementation; import
validation and active/completed IO traversal add necessary behavior. Lookup adds
two small workers. There is no new AST, index or intermediate representation.
These counts do not prove conceptual simplicity, and the earlier 50%/75%
reduction targets remain unachieved.

The ordinary host adds 12 lines and 939 bytes. Equality helper v5 remains
296 physical / 285 nonblank lines and 27,345 bytes; its tests and runtime are
unchanged. Research launchers, experiment reports, retained logs and generated
APIs are separate from these maintained Bend-source counts. The selected API
is 778,087 bytes, 5,444 more than Phase14.

| Artifact | SHA-256 |
|---|---|
| Selected API | `b8d658c564226a52764a435df86059aa3cea6b0c428bbde5341a62c2253c2e2d` |
| Genuine checked parent | `32ec77a35982f29d5e6f405a74236fdbff72810b8960459f1e26f4e3c126c1c9` |
| Assembled source | `fb5f557814beb6e4662d757861d4f912b0efaf04edf411d73d685435532e86a8` |
| Runtime | `1766d6d674f5c64eb481a647fe1d7bf751529d6861d4d4f4697999f005e772f0` |
| Base | `00c751b6cd045361a80f214c9c36bd4ec637e9ec86109b194e55cd57ca63ab94` |

This is a guarded derivative of a genuinely checked B1, not a new self-emitted
fixed point or independent BendTT validation. Ordinary compilation runs the Bend
implementation without TypeScript fallback. Kernel, GPU and interactive-device
coverage remain separate; `--verdict` is unsupported.

## Failed attempts and preservation

The evidence retains the first behavior selection's three incorrect control
expectations, the counter assertion that incorrectly demanded a load improvement,
the initial caret audit/control setup failures, the cycle precedence witness,
and the audit launcher that read an exact-difference field at the wrong level.
Individual reports identify exact tools, inputs, verdicts and corrected attempts.

Both first integrated builds genuinely compiled but failed their routine gates
32/36: upstream selectors retained strict diagnostics instead of the intended
custom acceptance/phase oracle. Those reports remain failed. The corrected
selection uses the documented custom-fixture mechanism; no harness or upstream
oracle was weakened. The first behavior variant also remains unselected because
of the newly exposed cycle precedence change. A second source preparation was
superseded before compilation solely to correct two graph-boundary comment lines.

The [independent review](integration-review.md), prospective
[plans](../../experiments/phase15/), [evidence protocol](evidence/README.md) and
machine-readable publication record preserve both failed and selected attempts.
All 75 unrelated Phase6 paths match their original identities and remain
unstaged. Evidence capture follows closed producers and an explicit root freeze;
capture completion never turns a failed compiler observation into a pass.


## Next frontier

The largest remaining exact-difference families are 166 legacy/unstructured
messages and 153 snippet-only observations. Another shared diagnostic cause has
more immediate conformance value than collecting isolated wording patches. The
seven old checker caret/span failures and eight direct parser-control gaps stay
explicit; matching rejection behavior alone does not prove the intended rule.

The source-worker pattern still pays, but this round gains 3.9%, not an order of
magnitude. Profile the installed image before another change. Addressing an
8.35× gap will likely require reducing representation/allocation work in a hot
path, with operation counts and exact history gates, rather than assuming another
two branch workers will close it. The larger Phase13 rewrite and rejected seed/
branch transformations remain uninstalled. Routine edits should keep using the
36-case checked workflow; broad conformance and evidence publication belong to
integration checkpoints.
