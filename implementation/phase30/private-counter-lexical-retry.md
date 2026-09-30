# Number countdown after lexical helper lowering

The prospective plan is `design/phase30/private-counter-lexical-retry.md`.
The generated-output acquisition `review-counter-lexical-01` uses the checked
attempt08 helper, with its lexical functions and literal shifts. It changes
only a guarded initial Number conversion, private zero comparison and private
decrement. There is no compiler or maintained runtime edit.

The unchanged module has SHA-256
`fa9cc6361f7d11e5e340d487f0ac918fd51212b82611b2a8baf247c847787da3`
and 76,658 bytes; the counter-only derivative has SHA-256
`1752bd5b9ae1d36ab546201a5884719fc71301e002f7f6794f19443a4898a92d`
and 76,672 bytes. Separate entry-sentinel modules are diagnostic artifacts and
are excluded from both timing configurations.

An independent static review found the liveness and guard boundary sound for
this frozen shape: the predecessor appears only in its immutable binding and
first self-tail argument; the next counter only binds, tests and decrements.
Conversion follows the exact-entry, scalar and complete live-closure guards.
Every admitted predecessor below `2^48-1` is exactly representable as Number.
The converted loop returns directly and cannot fall through to the generic
callback body.

This retains the existing stable host-intrinsic scope, including the global
`Number` function. Replacing that global with an observable callable would expose
the new conversion. Public compiler-generated descriptor mutation and invalid
scalar inputs remain covered by the original guard and fallback contract; they
are distinct from arbitrary replacement of host intrinsics.

The acquisition finished before the next exclusive timing batch started; the
timing owner confirmed there was no overlap. After the parent's global release,
the bounded CPU6 correctness controls passed:

- `review-counter-lexical-controls-01`: 121 independent fixture points across
  both variants, including 50,000 iterations; 28 saved-partial, counter-boundary
  and diagnostic-entry cases; 10,007 deterministic representability checks.
- `review-counter-lexical-abi-01`: 146 ordered ABI, mutation, coercion and
  primitive-prototype observations, plus 72 independent arithmetic observations.
- `review-counter-lexical-entry-01`: nine exact/raw/reentrant entry cases.

The diagnostic entry cases admit predecessor `2^48-2`, reject `2^48-1`, reject
invalid primitive/boxed/coercible representations, and retain generic entry for
raw callbacks, attempted permission forgery and changed helpers. They preserve
the actual conversion and decrement while replacing expensive result bodies
with sentinels; no astronomical loop was executed. The complete unchanged and
counter-only modules are the only timing variants. Performance measurement is
reported separately below; the old 1.052× result is not reused.

The timing owner completed `counter-lexical-confirm-01` under the parent's
exclusive CPU3 grant. The unchanged BigInt median is **0.010158616 ms**, range
0.010127661–0.010489782. The Number-counter median is **0.009612766 ms**, range
0.009442248–0.009742036: **1.0568×**, or about **5.4% less time**, with disjoint
sample ranges. The BigInt halves mostly differed by at most 2.01%, with one
7.88% improvement; all Number half-drift magnitudes were at most 2.18%. Every
timed output passed the independent expected result. The 42.59-second outer
duration is experiment wall time, not invocation cost.

The independent recommendation is to retain the simpler BigInt loop for this
phase. Lexical functions and literal shifts changed the surrounding cost, but
the private-counter improvement remains modest, close to the earlier experiment.
This confirms the hypothesis deserves remeasurement while also showing that a
second counter mode and additional liveness admission are not necessary to
obtain the much larger region-coverage gains. The derivative and its proof remain
available for a later compiler tradeoff; no production change was made here.
