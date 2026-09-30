# Phase26 U32 decision controls

The control suite targets emitted JavaScript semantics before measuring an
optimization. It does not modify compiler/runtime code or measure compiler speed.
The initial implementation is deliberately restricted to native U32 functions
with closed U32 literal results; the remaining fixtures challenge preservation of
the generic fallback and the existing native-identity refusal boundary.

## Cases and independent oracles

| Fixture | Boundary challenged | Expected observations per emitter |
|---|---|---:|
| `numeric-decisions` | Dense gaps, sparse order, unsigned full-width keys and default |468 scalar results|
| `captures-and-arguments` | Remaining arguments, nested matches and shared captures |468|
| `partial-higher-order` | Staged partial applications and a passed function |468|
| `structural-fallback` | Overlapping literal/bit patterns; bound head/tail bits are used |468|
| `structural-view` | Direct Word(32n) projection and reconstruction |468|
| `multiple-columns` | Row order, literal prefixes and default bindings |468|
| `branch-demand` | Unselected divergent default must remain unevaluated |8|
| `own-u32` | A checked local U32 with different constructors is refused by emission |1 refusal|
| `own-u32-constructor` | A checked local U32 constructor with a non-Word field is refused |1 refusal|
| `own-u32-literal-refusal` | A numeric literal cannot inhabit a local U32 declaring Foo |1 checker refusal|
| `shadow-base-refusal` | A local declaration cannot replace Base's native U32 |1 load/parse refusal|

Each ordinary scalar fixture exhausts all256 byte values with varying salts,
adds21 boundary inputs crossed with four seeds, and128 fixed LCG-generated
full-width input/seed pairs:468 calls. Important keys and their neighbors include
0,2^31,3,000,000,000 and2^32−1. The seven executable fixtures total2,816 exact
scalar observations per emitter. They are finite checks, not a proof over U32.
Expected arithmetic uses separately written JavaScript equations and unsigned
32-bit operations, without calling either emitted program or importing its code.

The structural controls derive their requirements from pinned upstream
`tests/compile/u32_table_bitvar.bend` and `tests/reg/u32_structural_view.bend`.
The nominal refusal derives from `tests/check/u32_literal_own_u32.bend`.
Phase25's dense/wide fixture experiments remain the performance witnesses; these
new fixtures add nearby semantic obligations rather than replacing those timings.

Refusal controls require the declared phase and a specific diagnostic fragment.
They do not accept any arbitrary exception and do not claim exact diagnostic-text
conformance. `checked` in this runner means the checker succeeded, whereas the
candidate driver's raw `checked` flag can also accompany a checker rejection;
the complete raw candidate observation is retained separately.

## Runner

From the repository root, use Node24.18.0 and a new output directory:

```sh
node selfhost/tools/performance/phase26/controls.mjs CONFIG.json NEW_OUTPUT
```

Example configuration (absolute paths are recommended):

```json
{
  "cpu": "6",
  "reference": "/absolute/pinned-upstream-checkout",
  "candidate": {
    "api": "/absolute/checked-attempt/compiler-api.mjs",
    "runtime": "/absolute/checked-attempt/snapshot/src/runtime.mjs",
    "base": "/absolute/checked-attempt/base.bend",
    "driver": "/absolute/checked-attempt/snapshot/tools/typed-driver.mjs"
  }
}
```

Omitting `candidate` makes an upstream-only fixture-development pilot. Optional
`cases` selects explicit fixture identifiers. Every emitter/fixture runs in an
isolated child with CPU affinity,4MiB stack,1GiB heap and30s default timeout. The
runner checks the source, emits an ordinary library and compares every acquired
result. A timeout on the demand witness fails the control; the divergent branch
itself is never an intended input. Child stdout/stderr, status, signal, errors,
full scalar observations and emitted modules are retained.

The output freezes sources, consumed runner/config and per-child settings, hashes
the compiler/runtime/Base/driver inputs, and verifies their stability at closure.
Its hashes identify the supplied candidate; the checked development workflow
remains responsible for verifying the candidate's full build provenance and
transitive host dependencies. No source identity or checked-B1 claim is inferred
from scalar agreement alone. This runner is deliberately not a timing harness.

## Preserved fixture development

- `selfhost/build/phase26/controls-pilot-01`: initial ten-case upstream pilot.
  Seven executable fixtures and two intended refusals passed. The original local
  U32 fixture additionally declared Bool; its checker passed but emission refused
  Bool's reserved name. That observation disproved the initial assumption that
  this user-defined native-name fixture could be executed.
- `controls-pilot-02`: the valid local U32 fixture now specifically reaches the
  U32 emission refusal. Ten of eleven rows passed, including all2,816 scalar
  observations. The newly added same-spelled constructor fixture initially tried
  matching a syntactically known constructor and was correctly rejected during
  loading, before reaching its intended emission obligation.
- `controls-pilot-03`: that fixture now matches a function parameter; checking
  succeeds and emission refuses the local U32 as intended. The earlier attempted
  source and raw rejection remain in pilot02. The final fixture set is ready for
  a fresh complete paired acquisition against an identified checked candidate.

These pilots are fixture validation only. All original source/tool versions and
failed observations are retained in their separate output directories for the
phase's durable evidence archive. Final promotion still needs the fresh paired
suite, the existing focused frontend/backend gates and separate controlled speed
measurements. Native C/device execution, foreign side effects and general
error-order equivalence are outside this bounded suite.

## Complete installed-baseline acquisition

`selfhost/build/phase26/controls-baseline-01/report.json` records22/22 successful
isolated processes against pinned upstream and the unchanged installed Phase24
API (`7b523bdffc0acde702dda1005a5e8201f7b65b2e432d1be95b07f2cfcc0346fa`). Both
emitters passed2,816 independent scalar observations and all four declared
refusals:5,632 scalar observations plus eight refusal rows in the paired report.
All recorded inputs remained unchanged. This is the first complete acquisition
of the final fixture set, separate from the source-development pilots.

The preserved `numeric-decisions-upstream/module.mjs` and
`numeric-decisions-candidate/module.mjs` are the reference and **old baseline**
artifacts for a same-window timing comparison. Here the runner's `candidate`
label refers to the installed compiler, not the later Phase26 optimization.
Their SHA256 identities are respectively
`3647ceff29dfb293d9f212f3214d5f478259cddf69279f57faea3f9abdb087fb` and
`2611975a0cbe479c5a3ca2b067d5f8139a35a3f531388402e610f768deb5e90b`.

## Review of emission and measurement tools

A separate read-through reviewed the root-authored Phase26 `emit.mjs`,
`corpus.py` and `measure.py`, including their Phase25 child/execute dependencies.
This reviewer authored the controls, not those acquisition tools.

The review requested additional identity closure checks before acquisition:
bind the original attempt manifest after emission, hash Node itself, and retain
the reused baseline manifest, sources, emitted modules, emission receipts and
execution helpers in the corpus's verified inputs. The updated tools now make
those checks, require a complete baseline manifest and match each reused
emission's source hash to the selected unchanged source. No remaining blocker was
found in this bounded review.

The measurement setup uses clean emitted modules, serial CPU3 execution,
separate calibration, fresh processes, per-side repetition counts and per-call
normalization. Five samples per variant use a rotating order; this is a controlled
screen, not a statistical guarantee. The calibration target is150ms, capped at
one million calls, so actual block lengths must remain visible. The caller is
responsible for choosing checked emissions and freezing intended inputs; the
timing runner itself does not establish compiler provenance or claim a full-H
measurement. No comparative timing was performed by this controls review.

## Checked candidate and ignored-bit supplement

Before the candidate acquisition, `verifyAttempt` accepted the immutable
`selfhost/build/phase26/attempt-01` as a checked derived B1, API
`4c67ac041c41d1e9ba5984ea29985a46ff7ee90963cb8eb820a7c82d91e7f664`.
`controls-candidate-01/report.json` then passed all22 isolated rows:2,816 scalar
observations and four declared refusals per emitter. The snapshot driver,
runtime, Base and API were supplied explicitly, and recorded inputs stayed stable.
The numeric candidate module is
`91097b07b07447a752bd736305651d7451c2e7b9f2792b526494cacbcecd3923`;
the newly emitted upstream module remains byte-identical to the baseline reference.

A reviewer identified a distinct accepted pattern shape: a structural bit arm
whose bound tail is ignored and whose result is a closed constant. The original
structural fixture intentionally uses its bindings and challenges fallback, so
it does not cover that shape. After the main acquisition completed, an opt-in
`constant-bit-arms` fixture was added; the consumed prior runner remains frozen
in the main acquisition. Select it with `"cases": ["constant-bit-arms"]`.

The supplement carries upstream's literal-prefix/odd-bit and catch-all-bit cases
across the same468-input full-width domain and adds two-bit prefixes with ignored
tails. Independent oracles use parity and the low two bits. The new
`controls-bit-arms-01/report.json` passed2/2 healthy processes and468 exact scalar
observations per emitter. It is separate evidence from the unchanged11-fixture
default suite. Neither acquisition is a timing result.

The nominal refusal fixtures exercise the public boundary before optimization;
they do not execute the optimizer on a fabricated book with corrupted native
flags. Any such internal provenance-guard controls require their own evidence.
