# Review of actual compiled local-data regions

Actual04 passes the additional independent fixture and full-pair checks. These
are outputs of the compiler's general source analysis, not the handwritten
generated-code derivatives used to select the architecture.

The reviewer authored the bounded type/native-recognition predicates in
`src/back/js/local.bend` after the initial prototype review. Root authored the
region/worker/emitter integration. The tests below use separately calculated
oracles; they are not a claim of fully independent review of every authored line.

## Generalization hazards found before promotion

Static review identified that a canonical Sigma tuple uses an Array representation
even when the source invokes no Array native. Selecting the stronger guard only
for Array-native dependencies would therefore miss an observable marker callback.
The shared tree-region analysis also needed the stronger guard. Root corrected
all root/worker/tree selections and retained candidate01's earlier scope.

Record matcher field slots must follow ordinary helper arguments rather than
shadowing them. Initial private zero arms need an argument rebind because their
first slot excludes the original Nat parameter; final zero arms use the computed
next values. Root's explicit initial IIFE and final aliases satisfy that boundary.

The first compiler images emitted `localGuard` calls before the regenerated
runtime bundle contained that function. Actual pair execution caught this
packaging failure; candidate02/03 evidence remains retained. No successful
execution result is attributed to those artifacts. Runtime regeneration and a
fresh checked04 build precede the successful results here.

## Two additional source fixtures

`review-fixtures/tuple-markers.bend` combines a scalar loop and a canonical tuple
with no Array native dependency. `review-fixtures/nested-records.bend` combines
computed nested record fields, two earlier scalar arguments, and a local loop.
Both are under `selfhost/tools/performance/phase31/` and were independently
emitted by checked17 and actual04. Their emission receipts require checked
acceptance and equal source identities before comparison.

The maintained `review-local-fixtures.mjs` reports **48 complete value points**
and **38 ordered boundary observations** in
`selfhost/build/phase31/review-local-fixtures-02/report.json`. Counts include
zero/nonzero and overflow values, helper binding getters/replacements, raw and
constructed callbacks, saved partials, slot mutation/throw/reentry, and public
record field getters/proxies. The generated private helper and root guard must
actually occur; a generic fallback cannot satisfy the structural admission gate.

An intentionally incorrect derivative replaces private `localGuard` calls with
the earlier scalar-only guard. An Array.prototype.request getter changes the
scalar helper `tweak` during tuple elimination. Checked17 and actual04 both
produce **209** with identical callback traces. The bad derivative produces
**9** because it ignores the changed helper. Its source, hash and expected
mismatch remain in the receipt. This is a concrete counterexample to the weaker
guard, not merely a hypothetical requirement.

The first fixture-control launch contained a missing JavaScript brace and stopped
before importing any module. Its stderr, original failed tool and outer receipt
are retained in `review-local-fixtures-launch-01`. The corrected second launch
completed in 0.215 seconds. These are correctness acquisition durations, not
comparative runtime measurements.

## Original complete pair and native effects

`review-actual-pair.mjs` independently implements the complete recurrence using
BigInt U32 arithmetic. It consumes the same checked row source emitted by17 and04;
the original `pair` source is unchanged. Actual04's pair must contain its private
root and guard all required helper/native dependencies.

| Pair index | Independent result | Checked17 | Actual04 |
| --- | ---: | ---: | ---: |
| 0 | 1866542166 | 1866542166 | 1866542166 |
| 17 | 226010650 | 226010650 | 226010650 |
| 4294967295 | 0 | 0 | 0 |

At index17, all four complete arrays in original allocation order agree. The
complete native schedule also agrees event for event:

- Four allocations, preserving 256/256/512/512-word storage.
- 262,401 reads, preserving each handle, index and value.
- 66,561 writes, preserving each handle, index and value.

All **328,966 events** are retained as compressed NDJSON for the independent
oracle and both observed modules. The report binds raw stream hashes and the
instrumented modules. No instrumented module is used for timing. Raw evidence
is `selfhost/build/phase31/review-actual-pair-01/`; the bounded CPU6 launch closed
successfully in 4.274 seconds, again only an acquisition duration.

These observations establish a useful local-data compiler boundary while keeping
the performance question separate. They do not establish full backend conformance
or support for arbitrary callbacks, foreign containers, erased generic helpers,
or escaping delayed results. The subsequent
[strict-result hypothesis](../../design/phase31/fully-demanded-private-results.md)
is a distinct prospective transformation with its own proof and validation needs.
