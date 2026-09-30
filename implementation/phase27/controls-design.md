# Phase27 selected-arm semantic controls

The controls test selected constructor-arm prebinding through the production
`j_library` export. They preserve the old generated program and independently
check output, field/argument order and partial descriptors before comparing the
candidate's complete observable transcript. No compiler/runtime code is changed
by this harness, and it exposes no private compiler functions.

## Domain and witnesses

`selfhost/src/back/js/test-arm.mjs` constructs a small synthetic KDef book with
ordinary record datatypes and eleven function shapes. This bypasses frontend
admission deliberately: it tests the actual emitter/runtime contract, including
trusted foreign record layouts and unusual field-vector behavior. It does not
claim that these synthetic KDefs passed type checking. Root-owned normal Bend
corpus and upstream execution acquisitions supply separate pipeline evidence.

Five candidate shapes must contain the `prebind-arm` lowering marker:

- A two-field record arm with four explicit leading lambdas.
- The same arm under an annotation.
- An arm closing over an earlier shared argument.
- An explicit arm whose eventual body calls an effectful host function; the
  effect must wait until all remaining arguments arrive.
- An arm returning a function field, including subsequent overapplication.

Six shapes must retain the old emitted fallback: an effectful non-lambda arm
factory, an erased constructor field, an eta-short function-field arm, an arm
whose arity equals its field count, a zero-field constructor and a deeply lifted
lambda chain. The effectful arm factory runs at match time; the effectful body of
an explicit partial arm runs only at saturation. These are distinct obligations.

The primary returned partial must retain `arity:4`, `env:null`, two copied bound
fields and the original function body. The harness compares own property keys
and attributes, bound holes, function name/length and function-source hash with
the baseline. Further partial application preserves the code/env identities and
does not mutate the earlier bound vector. Captured values and all constructor
fields/later arguments retain their independent expected order.

Additional controls cover saturated, staged, higher-order and overapplied calls;
owned snapshots after source mutation; frozen arrays; sparse holes; named foreign
fields; trusted records with an unrelated tag; left-to-right accessor reads;
early field/slice exceptions before a later argument expression; and projection
vectors of length0 through5. Incorrect-length foreign vectors must keep the old
generic outcome rather than gaining a new rejection or silently dropping fields.

Custom `slice` methods return vectors of length0,1,2,4 and5. Source-array and
returned-vector proxies record property access order. Separate changing-length
getters vary the source length during native `slice`, and the copied-vector
length across the old equality/underapplication/overapplication decisions. The
zero-length projection must not read `slice`. These finite traces challenge the
actual snapshot/application schedule; they are not a theorem covering every
possible adversarial proxy or custom species implementation.

## Frozen baseline and inline-candidate outcomes

Both expanded inline-variant acquisitions ran on CPU6, Node24.18.0,4MiB stack/1GiB heap:

| Acquisition | Compiler API | Result |
|---|---|---|
| `selfhost/build/phase27/arm-baseline-02` | Installed Phase26 `4c67ac041c41d1e9ba5984ea29985a46ff7ee90963cb8eb820a7c82d91e7f664` |72 asserted observations; all eleven shapes generic|
| `selfhost/build/phase27/arm-candidate-02` | Verified checked attempt01 derivative `4edd60a0ede8a8dd6ce560b93c694f1153af6dc6e8b8123abb7efdb53ab36c39` |72 asserted observations; five eligible shapes prebound, six fallback|

Candidate observations match the baseline transcript exactly, including
descriptor metadata, output values and recorded accessor/effect sequences. Each
candidate shape also meets its independent expected output/behavior assertions.
The count72 includes descriptor/trace observations; it is not72 independent Bend
source files or an expanded backend-conformance denominator.

The earlier `arm-baseline-01` and `arm-candidate-01` passed68 observations each.
They remain preserved, superseded only by adding function-name/length metadata
and four observations for the two changing-length getter scenarios. No compiler
counterexample or failed acquisition was discarded during this suite.

The candidate's immutable attempt was verified with `verifyAttempt` before use.
Each acquisition freezes its consumed harness/config and KDef book, preserves
the emitted program, records API/driver/runtime/Base identities and verifies
those inputs remain unchanged. Build provenance remains the responsibility of
the checked workflow; this synthetic execution harness does not manufacture a
checked-compiler claim from output agreement.

## Reproduction

Create a JSON config containing
`candidate:{api,runtime,base,driver}` with absolute paths. For a checked attempt,
use `attempt.json`'s API/runtime/Base and its snapshot `tools/typed-driver.mjs`.
Set `expectPrebinding:false` for the preserved Phase26 baseline and `true` for
the candidate. Supply `baseline` as the baseline report path to require exact
transcript equality:

```sh
taskset -c 6 node --stack-size=4096 --max-old-space-size=1024 \
  selfhost/src/back/js/test-arm.mjs CONFIG.json NEW_OUTPUT_DIRECTORY
```

The output directory must not exist. A failed assertion produces a nonzero exit
and retained report. Do not run these acquisitions alongside a comparative timing
window. No duration from this harness is a performance result.

The Phase26 full-width numeric suite was also rerun against the Phase27 candidate
at `selfhost/build/phase27/phase26-controls-01`:22 healthy paired processes,
2,816 exact scalar observations and four expected refusals per emitter. The
separate constant-bit-arm supplement is recorded in `phase26-bit-arms-01`.
It passed two healthy processes and468 exact scalar observations per emitter.
Those controls protect the previous numeric optimization and keep their own
scope; they must not be added to historical full-suite counts.

## Shared-runtime variant

The second variant follows the separately written
[shared-runtime design](../../design/phase27/shared-arm-runtime.md). It moves the
prebinding callback into `matcher1p` while preserving the original code factory.
The same marker and contracts are retained, so **the72-observation harness did
not change** between the inline and shared variant acquisitions.

`verifyAttempt` accepted immutable attempt02 before execution. Its API is
`5a89c775e903374341da4b4e32c29d26ffe687677f088c590046f748b69d81c5` and its runtime is
`40823818afd57a6c37e055272dc332f461955a7cd225f67d66194f0d43ec823f`.
`selfhost/build/phase27/arm-candidate-03/report.json` passed all72 observations
against the unchanged `arm-baseline-02` transcript. The five positive and six
fallback shapes remain as specified. Code name/length/source, null environments,
bound snapshots and all recorded side-effect/property-read sequences agree.
This acquisition used the new immutable runtime; it did not substitute the
baseline runtime to make a guard pass. Earlier inline evidence is retained.

The shared variant also passed `phase26-controls-02`:22 healthy processes,
2,816 scalar checks and four expected refusals per emitter. Its separate
`phase26-bit-arms-02` acquisition passed two healthy processes and468 scalar
checks per emitter. Inputs remained stable in all three shared-variant control
reports. These are fresh scoped regressions, not an additional full-conformance
claim or performance measurement.
