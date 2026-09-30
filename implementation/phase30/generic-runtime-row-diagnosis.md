# Generic runtime regression: exact-state row diagnosis

Checked14 is held after the complete original-program matrix exposed common
generic-path regressions. This experiment keeps one checked source and its
complete output fixed while changing only independently reviewed runtime
dispatch expressions. It does not use the earlier private row/cell/native-array
ladder and makes no new compiler-source change.

Fresh Phase29 and checked14 emissions of
`prototype-owned-source-01/row.bend` completed in 5.125 and 5.276 seconds,
respectively, with checked receipts. The original pinned TypeScript emission
uses exactly that source. All seven adapters serialize the complete four
128-slot arrays from `row.probe`; all 28 independent length/seed states agree
across all seven variants (196 comparisons).

| Variant label | Meaning |
| --- | --- |
| phase29 | Newly checked Phase29 emission |
| baseline | Newly checked held14 emission |
| inline | A: inline ordinary exact-application dispatch |
| generic | B: restore delayed generic constructor-field application |
| fused | B alternative: registered direct literal matcher |
| actual_call | C: retain the historical `code.call` read expression |
| typescript | Pinned upstream, same source |

The two retained alias/effect suites compare14/A/B/C and14/A/fused/C. Each passes
28 state oracles, 16 alias observations and 257 ordered/public boundaries.
Only the unrelated private-owned-region admission-sentinel section was removed
from the original harness; all runtime/evaluation assertions, observation
normalization and mutation restoration remain unchanged. Phase29 is a numeric
baseline, not the reference for already repaired public boundary defects.

Independent runtime/helper suites belong to each derivative owner and are bound
in `runtime-row-adapters-01/derive.json`. B's separately retained ambient
`io`/`typeName` prototype differences are classified against literal matcher
semantics as restored observations; they are not silently normalized away.

The frozen seven-way timing configuration is
`runtime-row-timing-plan-01/screen.json`; the point is length32, seed17. The
screen completed under an exclusive CPU3 grant in 12.99 seconds. Median
milliseconds were Phase29 0.674038, checked14 0.870054, A 0.854715, B-generic
0.685677, B-fused 0.842583, C 0.786151 and TypeScript 0.009235.

This screen implicates generic constructor prebinding, but its warmup is far
from settled: Phase29/B-generic halves improve 43–45%, while checked14/A/fused
halves worsen 46–50%. C worsens 32–53% and TypeScript improves 8–9%. The raw
screen is retained as mechanism evidence; its apparent gain is not accepted as
steady throughput. Confirmation, selection and transfer remain parent decisions.

## Maintained confirmation

The unchanged seven-way confirmation completed in 147.51 seconds. All outputs
pass. The five sample ranges below are milliseconds per complete row call.

| Variant | Median | Minimum–maximum | Half drift range |
| --- | ---: | ---: | ---: |
| Phase29 | 0.450682 | 0.447820–0.457179 | +1.10…+3.11% |
| Checked14 | 0.606265 | 0.589693–0.614176 | −4.03…+1.29% |
| A inline | 0.610321 | 0.605481–0.644570 | −1.30…+0.45% |
| B generic | 0.446850 | 0.445177–0.455656 | −1.04…+3.76% |
| B fused | 0.592224 | 0.587821–0.596139 | −0.68…+0.93% |
| C method read | 0.547576 | 0.539989–0.549176 | +0.86…+1.38% |
| TypeScript | 0.008408 | 0.008367–0.008457 | +1.17…+2.12% |

B-generic takes 26.29% less time than checked14 (1.357× throughput), with
disjoint ranges, and recovers Phase29 performance: its median is 0.85% lower
with overlapping ranges. C saves 9.68%; B-fused saves 2.32%; A is 0.67% slower
with overlapping ranges. Thus the generic constructor-field application path
is the strongest isolated mechanism in this row. Restoring it is simpler than
the more elaborate fused prebinding alternative, which recovers little here.

This result does not prove that every original regression has the same cause.
The remaining work is actual compiler/runtime integration, complete boundary
verification and original-program transfer. No source change or combination of
derivatives is included in these measurements. Raw comparisons and launcher
receipts are `runtime-row-screen-01` and `runtime-row-confirm-01`.

## Actual checked15 integration

The parent selected only B-generic. Checked15 retains exactly checked14's
compiler API hash (`ade96ba48b05ba116430f57e433d8fbdbd76646b61f5e9d53cf34a4c4a9da76d`)
and changes the runtime hash to
`3b0c374dadd819c2edf3b92c7b64a79ad17dbe67c48bf5cb22451a3a575fcfa4`.
Fresh row/helper/Mandelbrot emissions take 5.276/4.975/5.326 seconds to acquire.

`runtime-actual-proof-15b/report.json` proves all three complete modules equal
their independently reviewed B outputs after only the prospectively declared
runtime-comment change. No executable byte is normalized. The first proof
launcher failed before execution because its Python source used the reserved
word `pass` as a keyword argument; the exact failed tool and stderr are retained
in `runtime-actual-proof-15-outer`. Correcting only that syntax and using a fresh
output directory produced the passing proof; there was no semantic mismatch.

The fresh actual row passes 140 complete-state observations across
Phase29/held14/checked15/B/TypeScript. The actual-image boundary suite passes
28 state oracles, 16 alias observations and all 257 ordered/public boundaries.
The previously executed B helper ABI/numeric/entry/cell gates transfer through
the complete-module proof; this avoids pretending that a duplicate execution is
additional independent evidence.

`runtime-actual-timing-plan-15/confirm.json` freezes same-window row32 and
scalar128 comparisons across Phase29, held14, actual15 and TypeScript. These
measurements remain frozen and unexecuted: the parent chose one combined
checked16 comparison instead of duplicating this 15-only run. Original-program
transfer and the remaining release gates are still required.

## Actual checked16 source cleanup

Checked16 removes the unused prebinding emitter/runtime bridge. Independent
structure reports prove that only recognized constructor sites change and all
unrelated generated AST fields remain equal to checked15: the row has six
literal sites; the helper has one registered Nat wrapper; original Mandelbrot
has two literal sites and three registered Nat wrappers. Each module removes
exactly one obsolete runtime bridge. These are structural proofs, not arbitrary
text normalization or a claim that the emitted modules are byte-identical.

The fresh checked16 row passes 168 independent full-state comparisons across six
variants. Its actual-image suite retains all 28 oracles, 16 alias observations and
257 ordered/public boundaries. Focused helper, entry, callable-kind and arm
gates also pass under the independent reviewer. All ten original programs have
been acquired from checked16 and pass their exact public results in 70.01 seconds.

The frozen `runtime-cleanup-timing-plan-16/confirm.json` includes Phase29,
held14, runtime-repaired15, cleaned16 and TypeScript on row32 and scalar128.
It completed in 209.80 seconds: row medians Phase29/14/15/16/TS are
0.448173/0.601983/0.448121/0.444585/0.008421 ms. Cleaned16 retains repaired15 and
Phase29 speed within overlapping ranges and removes 26.15% of held14 row time.
Scalar128 medians 14/15/16 also overlap; 16 retains 56.83× Phase29 throughput and
4.096× TypeScript time. Full ranges and drift are in `final-timing-16.md`.
Final16's original-ten, ordinary compiler cost,
library-generation cost and scaling plans are also frozen separately, with
their established protocols; their complete durable batch binds 751 identities.
Conformance and a coordinated timing grant precede execution and release.
