# P11-002 — Compress native Nat reconstruction before continuation lowering

- Owner: backend-pattern agent; independent integration/review: root.
- Started: 2026-09-28. Initial read-only investigation bounded to ten minutes.
- Baseline: Phase10 release, repository5f561c45e2e86c1e35e0ede8c73ab4342ae50e61;
  selected APIff876a357db2d44d3e1fbd37ab694a16d2fa0f47d60c9d500603e634c8c645f9.
- Pinned upstream: b2111cf; unchanged human-written TypeScript sources.
- Correctness/measurement: prospective; no candidate or new timing yet.
- Report: [patterns.md](../../implementation/phase11/patterns.md).

## Hypothesis and smallest falsifier

Pinned comp.ts `tpl_nat` fuses successive Nat increments into a checked offset.
The Bend backend only compresses closed literals; every open Succ constructor
otherwise receives generic argument sequencing and a continuation segment.
Deep-pattern default reconstruction repeats open Succ prefixes, multiplying the
number of native segments and emitted C bytes. Count actual compacted terms and
segments for Nat depths8/16/32/64 before a source change. No superlinear segment
series or no segment reduction disproves this proposed intervention.

Rank a native-only post-erasure offset representation first: user constructors
have already been renamed and checked erasure establishes native identity. Keep
frontend flattening, exact source diagnostics, checker/termination rules, JS
emission and public value representation unchanged. A broader shared compact
pattern/let representation could benefit every pass but has much larger proof
and annotation obligations; defer it until the cheaper backend candidate is tested.

The candidate must evaluate its dynamic tail exactly once and retain erasure,
reference discovery and failure order. Positive increments can combine only under
a sound overflow argument; explicitly test the native immediate boundary and
forged/foreign out-of-range input rather than assuming host U64 addition is safe.
Preserve closed literal behavior and custom constructors named Zero/Succ.

## Controlled scope

Use isolated copies of immutable Phase10 integrated01, genuine checked B1 build,
current guarded equality derivative, Node24.18.0, CPU1, 4MiB stack/4GiB heap.
Record all source/API/runtime/Base/host/helper/toolchain/input identities and
original failed attempts. Small raw controls and source checking precede actual
JS/native output gates. Native emission/build each has a separate90-second bound;
smaller probes use30-second bounds. Coordinate compiler launches with root.
Concurrent exploratory times are never compiler-wide speed ratios.

Require exact existing refusal phases/diagnostics, custom Nat identity, erased
costly arguments, dynamic-tail dependency/refusal, Nat offsets0/1/256/257/300,
computed values beyond source U32 and native cap boundaries. A changed refusal,
skipped/eager field, repeated tail execution, malformed native output or inherited
candidate from a rejected historical prototype blocks promotion. Root owns any
production edits, final broader suite, exclusive timing and release.
