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
was tested separately in the subsequent candidates below.

## Fully demanded results, redundant demand removal, and direct reads

The follow-up changes were separated into three checked compiler artifacts:

| Artifact | Only new semantic transformation | Independent pair/state/event replay | Additional structural fixtures |
| --- | --- | --- | --- |
| Actual05 | Return fully demanded values from private helpers/zero arms; retain private call forcing | PASS: three BigInt results, four arrays, 328,966 events | PASS: 88 values, 52 ordered observations |
| Actual06 | Remove the now redundant private call forcing | PASS: same complete comparison | Not reacquired by this reviewer; owner fold/public controls run separately |
| Actual07 | Replace private record/Sigma projection copies with type-proved positional reads | PASS: same complete comparison | PASS: 88 values, 52 ordered observations |

Every row compares a fresh checked emission of the identical source against
immutable checked17. Pair receipts are
`review-actual-pair05-01`, `review-actual-pair06-01`, and
`review-actual-pair07-01` under `selfhost/build/phase31/`. Each retains independently
calculated complete event streams, observed streams, and physical array state.
The final 07 replay took 4.073 seconds; it is a correctness gate, not a timing
sample. No native write or read was removed, reordered, or assigned to a
different handle in these comparisons.

The additional source `review-fixtures/nested-products.bend` adds a zero-field
ordinary record and a nested canonical Sigma containing two further products.
Its 40 scalar points include zero, positive loop counts, and U32 overflow. Together
with the earlier two fixtures, 05 and 07 each pass 88 value points and 52 ordered
boundary observations. Raw reports are `review-local-fixtures05-01/report.json`
and `review-local-fixtures07-01/report.json`. Public record getters/proxies and
argument slot mutation, reentry, and throwing retain their full baseline traces.
The 07 fixture acquisitions bind the actual07 compiler receipt and source hashes;
their roots must contain admitted private helpers rather than merely pass through
the public fallback.

The Array marker counterexample remains sensitive in 07. Correct 17, 04, 05 and 07
produce 209 and the same complete callback trace. The deliberately weakened guard
produces 9. After direct reads remove generic projection, that bad derivative may
omit the marker getter completely, so its old auxiliary `changed === true`
assumption was removed before 07 execution. The required correct trace comparison
and wrong-result witness were retained. Earlier consumed test versions and
receipts remain unchanged.

### Structural audit of every private worker

`review-private-results.mjs` parses the actual emitted JavaScript with the pinned
Node 24.18.0 bundled Acorn 8.16.0 parser, retaining its bytes and identity. It visits
every emitted private `$R` declaration and every nested IIFE/zero-arm return.
The AST walk has explicit source and node limits. It rejects calls to generic
`build`, `jump`, descriptor application/creation, or matcher operations inside
private workers, and rejects direct function-valued or missing returns.

| Actual emitted module | Private workers | Return nodes | Private force calls | Private project calls |
| --- | ---: | ---: | ---: | ---: |
| 05 | 35 | 51 | 20 | Retained |
| 06 | 35 | 51 | 0 | Retained |
| 07 | 35 | 51 | 0 | 0 |

All three pass the scheduler/descriptor prohibition. Receipts are
`review-private-results05-01`, `review-private-results06-01`, and
`review-private-results07-01`. The 05 structural result preceded force removal;
the 06 and 07 modes explicitly require zero remaining forces. The 07 mode also
requires zero private generic projections. Public generic operations remain in
the module and are exercised by the hostile-entry checks.

This inventory complements the source proof; absence of certain call names alone
does not establish soundness. The source proof depends on the closed private
grammar, scalar public boundaries, exact native and constructor ownership,
left-to-right argument/field demand, and rejection of recursive helper cycles.
Self-tail Nat edges use loops; other helper nesting has the existing bounded
admission depth. The
[fully demanded result proof](../../design/phase31/fully-demanded-private-results.md)
explains why private return work meets the same demand site, while the
[direct read proof](../../design/phase31/direct-private-field-reads.md) explains
why ordinary records use their own `.a` vector and canonical Sigma uses its dense
Array representation. Explicit IIFE arguments capture every field in original
left-to-right order before the arm executes, including helpers with scalar
argument prefixes. This proof does not admit arbitrary foreign containers or
escaping delayed results.

## Final07 static review and inherited runtime controls

A second source review compared the immutable final07 snapshot against
Phase30-17 across local-type recognition, region analysis, loop emission, private
expression emission, tree guards, and runtime registration. No correctness
blocker was found within the existing stable-host-intrinsic scope. In particular:

- Root eligibility still requires public scalar inputs and the prior restricted
  result type. The broader local signatures apply only inside the closed graph.
- Native calls require canonical ownership, the complete telescope, exact
  saturation, and a statically checked erased U32 argument. The erased argument
  retains its null runtime slot. Ordinary records and canonical Sigma obtain
  different layouts from type evidence, not constructor spelling.
- Native helper dependencies enter the same definition-time descriptor guard;
  native bodies are not emitted as private user functions. Every public private
  region uses the stronger Array-aware guard.
- Initial private zero arms rebind ordinary inputs through an IIFE; final zero
  arms bind the computed next values. The `Ann`-based zero dispatch receives
  analyzed plans only: public plans retain their lambda prefixes, while private
  plans contain the positional result annotation. An arbitrary source annotation
  cannot select that private arm through current callers.
- Direct reads preserve the full field telescope and left-to-right snapshot
  order. Stable Object/Reflect/Array intrinsics remain an explicit assumption;
  arbitrary replacement of Array copying/iteration methods is not a newly
  claimed compatibility guarantee.

Two small cleanup opportunities remain: `j_region_local_field_count` has no
callers, and `j_region_declarations` only forwards to `j_region_definitions`.
Each occupies four source lines. Removing them would reduce dead or forwarding
surface without changing the architecture; this review leaves the measured
artifact unchanged.

The earlier **55 runtime registration/guard controls** also cover final07's exact
runtime bytes. `review-runtime-identity.py` binds their successful receipt to
the final core and Base fragments, proves both fragments occur intact in the
packaged runtime, and verifies that 04 and 07 have the identical packaged runtime
hash. The static attestation is
`selfhost/build/phase31/review-runtime-final07-identity-01/report.json`.
It contains an optional explicit final07 command, recorded as unexecuted.
No JavaScript module was executed during this identity audit and no already
passing control was repeated. Actual07 generated-code integration is covered by
the fresh pair, fixture, and hostile-boundary checks above.
