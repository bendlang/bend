# Candidate03 selected JavaScript and interpreter execution

Date: 2026-09-28. This is an initial focused gate against upstream
`b2111cf43244e65f76ddc278ee695e669f720cbf`, separate from the full frontend
baseline and from final release promotion.

The frozen candidate03 API is
`1f224bce2114db25402f91db506e85612920c2c43107585832776ec2a04f6c1f`;
its runtime is `3b15c9758cd57ab41aa8e4df4b2f001cb52f4b91010d63dd7ea9a1b375742524`,
and host driver is
`af1d89a49fe001be428ced9e90674354f134e3c5bc2e598373c700e79a048c6a`.
Both host and frozen harness target manifests have identity
`ab7eea752c873a2f3948c2343087016888725248dfaab4d42689d9291ea58ddc`.
The canonical Base came from the pinned upstream checkout.

## Scope and result

The initial selection contains 37 fixtures, each executed through the interpreter
and JavaScript lanes: **74 actual observations, 64 pass and 10 fail**. CPU2 ran
one isolated worker at a time with a 30-second request cap, 4 GiB heap and
4 MiB stack. All fixture `#|` output and exit expectations stayed unchanged.
There were no timeouts, crashes, changed inputs or changed artifacts.

The selection includes all 21 runnable IO fixtures whose names contain
`foreign`, `marshal` or `cid`; Process.run and its parallel control; TCP bytes,
thread count and program arguments; all three new mutual-type fixtures; and
eight import controls. Declaration-only IO support fixtures have no execution
lane and remain covered by the full frontend/trust gate. Remaining import
execution cases have not been silently counted as covered.

| Fixture | Interpreter | JavaScript | Finding |
|---|---|---|---|
| `io/tcp_bytes.bend` | Fail, then pass with permission | Fail, then pass with permission | Sandbox denied loopback listen |
| `check/mutual_type_def.bend` | Fail | Fail | Checker refuses `Vec.Nil` as an unfilled definition |
| `import/respelled_first.bend` | Fail | Fail | Loader rejects a second spelling of the same source |
| `import/respelled_second.bend` | Fail | Fail | Same canonical-module gap, reverse order |
| `io/marshal_tag_unknown.bend` | Fail | Fail | Invalid foreign constructor tag is accepted |
| Other 32 selected fixtures | Pass | Pass | Exact expected output/exit |

Process.run (including limits, child exit and inherited pipes), its parallel
control, IO.args and thread_count all pass both lanes. Twenty of the 21 selected
foreign/marshalling fixtures pass both lanes. Two of the three new mutual-type
fixtures pass both lanes. Six of the eight selected imports pass both lanes.

The unknown-tag case is a real execution mismatch: a foreign function returns
`{$: "Bogus", n: 5n}` when `Box` has only constructor `Box`. Candidate03 prints
`6` twice and exits 0. Upstream requires the first `6`, then an exact explanatory
invalid-tag error and exit 1. Because the expected output starts with `6`, this
fixture is classified as a positive expectation; strict execution output still
catches the missing refusal. A successful check alone cannot validate this seam.

## Independent reference and permission controls

All **eight matching live TypeScript execution probes** for the four actual
compiler/loader/marshalling gaps pass their exact fixture expectations. This
rules out treating those failures as stale fixture expectations.

The ordinary-sandbox TCP failures printed `no free tcp port`. A separate local
listen preflight explicitly returned `EPERM`, and both failing observations are
retained. After coordinating with the native test owner to avoid shared ports,
the same frozen candidate API/driver/runtime passed **both TCP execution lanes**
in a narrowly elevated retry. The initial 64/74 report remains unchanged; the
permission result supplements it rather than replacing failed rows.

Evidence directories are `selfhost/build/phase8/candidate-execution-01` (frozen
harness, selection, candidate vectors, matching reference vectors, generated JS
and the explicit EPERM preflight) and
`selfhost/build/phase8/candidate-tcp-elevated-01` (the two successful scoped
retries). Root owns fixes and later frozen candidates. This gate does not claim
full backend conformance, mathematical kernel validation or a runtime speed gain.

## Foreign-tag repair: rejected first attempt and passing correction

Two fresh runtime-only attempts reused the exact candidate03 API and driver
above. They do not establish a new compiler bootstrap or fixed point. Each
attempt freezes its runtime, runtime fragments, selection and hashes in
`selfhost/build/phase8/runtime-foreign-01` or `runtime-foreign-02`.

The first guard rejected every inbound value whose resolved descriptor was an
ADT without a valid object constructor tag. That includes legitimate native
primitive representations. Its runtime identity is
`a1bbae4c6f1fb24ade8e7f085c61ed48eb73956e99909a9689e8405babbb0028`.
The unchanged 21-fixture, 42-lane gate produced **8 pass and 34 fail**. Even the
unknown-tag fixture failed prematurely on the valid Nat field of its first Box.
This failed attempt remains intact.

The correction follows upstream's Nat-marshalling boundary: tag validation is
needed for aggregate conversions that contain Nat, while native primitive
values keep their existing representation. Runtime
`78845fd6a99d90fa1dba8093c8af81a5665bc95ca0b69691adc9e366ac5665e7`
passes **42/42 observations**, including the exact unknown-tag output and exit
status. `selectedComplete` is true; the full-corpus `complete` flag remains false.
Both attempts have no changed inputs or artifacts.

`selfhost/src/runtime/js/test-phase8.mjs --foreign-only` additionally passes
direct checks using realistic recursive descriptors for Nat, U32, F32, Bool and
String. Controls cover native scalar boundaries, nested invalid tags and Nat
conversion inside arrays and tuples. This mode runs without network effects;
the original full effect controls remain available. Its stdout and stderr are
retained in `runtime-foreign-02/direct-tests.*`.

The 42 passing rows did not exhaust the descriptor cases. A separate direct
falsifier found that `Maybe(Nat)` and `Maybe(Bool)` inside one aggregate can hide
the Nat when the traversal suppresses the second occurrence of the generic name.
Runtime02 returned `hasNat: false`; upstream's traversal inspects type arguments
before its seen-name guard. The original pass vector and the later failing
falsifier are both retained. The correction visits each Named descriptor's
arguments before suppressing repeated definition expansion.

Runtime03 passes **44/44 execution observations**: the previous 42 plus both
lanes of a new actual foreign fixture, `phase8-fixtures/marshal_generic_nat.bend`.
The fixture supplies an invalid outer constructor tag for an aggregate with
distinct Maybe instantiations and requires the exact boundary error and exit 1.
The strengthened direct foreign-only unit also passes. All runtime03 inputs and
artifacts stayed unchanged. This extends the earlier gate without revising its
scope after the fact.

The runtime03 identity is
`1766d6d674f5c64eb481a647fe1d7bf751529d6861d4d4f4697999f005e772f0`.
Both live TypeScript probes of the new fixture pass. Both probes against the
preserved runtime02 fail by printing `good` then `unexpected acceptance` and
exiting 0. Thus the supplemental case demonstrates a real execution error,
not only a suspicious descriptor count. These controls remain separate files
under `runtime-foreign-03/generic-{reference,runtime02-control}.json`.

## Candidate06 import and owned-name controls

Candidate06 API `e928f77778de9dc72267e26b6a7ccb029cac318ccd35dd8f9248da1c6374bbe4`
comes from its recorded genuine checked bootstrap. A fresh capsule covers all
49 import fixtures in parse/check and every eligible positive-main interpreter
and JS lane, plus `check/name_owned_def.bend`: **50 fixtures, 135 observations**.
All **35 execution rows** pass (18 interpreter and 17 JS), as do all **40 positive
parse/check rows**. Both respelled-module fixtures now pass. The owned-name case
passes parse, check, interpreter and JS after removing the obsolete `Clo.apply`
prohibition. Native execution is the separate native owner's gate.

The three earlier import false acceptances (`alias_shadow`, `alias_twice` and
`shadow_base`) now refuse before type acceptance. The only accepted negative
import fixtures are the three expected proof-trust cases, all of which produce
verdict refusals. Their type acceptance is not confused with unsafe validation
acceptance.

Exact negative compatibility remains incomplete: the capsule totals **77 pass,
30 observed and 28 fail**, with **22/50 strict check passes**. Different error
text, phase or trust provenance remains a failure. There are no timeouts,
crashes or changed inputs/artifacts. Raw evidence is
`selfhost/build/phase8/candidate06-imports-02`; the preceding `-01` directory
preserves a selection-preflight failure because `base_prelude` does not enable
the JavaScript backend. No compiler probe ran for that invalid first selection.

## Durable evidence

The [selected execution archive](selected-js-evidence/README.md) retains all
these completed attempts, generated programs, raw observations, failed controls
and frozen candidate03/candidate06 API/source/host inputs. It contains 2,503 path
identities and 1,685 content objects in 6,315,169 compressed bytes, SHA-256
`979c49ea277715353669c4ceb5da0373c97990ea6e071a54669958ae8bf243cb`.
Every archived object and every unchanged original was verified.

## Final release07 combination

The isolated runtime experiments above do not substitute for exercising the
final compiler/runtime combination. A fresh run with release07's frozen API,
driver and runtime passes **44/44 actual interpreter/JS observations**, including
the generic-instantiation regression. `selectedComplete` is true; there are no
changed inputs/artifacts, timeouts or crashes. Evidence is
`selfhost/build/phase8/release07-foreign-01/candidate.json`.

Release07 combines API `e928f77778de9dc72267e26b6a7ccb029cac318ccd35dd8f9248da1c6374bbe4`
with runtime `1766d6d674f5c64eb481a647fe1d7bf751529d6861d4d4f4697999f005e772f0`.
The recorded transfer identities establish that candidate06 and release07 share
the exact API, driver, compiler ABI, Node resource policy, assembler, typed
adapter and compiler target manifest. Their runtime differs and was therefore
actually retested. Candidate06's raw frontend observations remain labeled with
their original source artifact. The final gate is retained separately in
`selected-js-evidence/release07.tar.gz`; the original archive stays unchanged.
