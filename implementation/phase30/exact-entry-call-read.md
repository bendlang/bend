# Authorize entry from the actual `code.call` value

Status: isolated emitted-runtime ablation passes the scoped controls; clean timing
is pending. No maintained runtime or compiler source changed. The prospective
design is [exact-entry-call-read.md](../../design/phase30/exact-entry-call-read.md).

The experiment freezes attempt07's scalar helper and original small edit-distance
outputs. It replaces only `invokeExact` in each file. Every byte outside that
function remains unchanged; the original function text is identical in both
inputs. The derivation and exact identities are retained under
`selfhost/build/phase30/inspection-exact-call-01/`.

For registered callbacks, the candidate reads the required `code.call` property
once, then `f.env` once. If the method is the captured native builtin, it installs
the existing single-use exact-entry token and invokes the same callback. This
removes one prototype lookup, two own-descriptor lookups and one `hasOwn` check
from the normal registered-entry path. All token consumption, restoration,
generated functions, purity guards and application/overapplication rules remain.

A custom callable method receives its original receiver `code` and arguments
`(env, all)` through the captured method value, without entry permission. A rare
noncallable branch uses a temporary `{call: invoke}` facade solely to preserve the
engine's existing `code.call is not a function` diagnostic without rereading the
original accessor. Ordinary successful calls allocate no such facade.

## Controls

All tests use the same frozen emitted runtime on both sides:

| Receipt directory under `selfhost/build/phase30/` | Result |
|---|---|
| `inspection-exact-call-abi-01` | 146 ordinary/prototype observations and 72 scalar-oracle executions pass |
| `inspection-exact-call-entry-01` | Nine actual callback reentry/order controls pass |
| `inspection-exact-call-controls-01` | 91 focused paired observations and 121 scalar points pass |

The focused observations exercise own/inherited/Proxy-prototype native method
lookups; custom ordinary, bound and Proxy methods; call and environment getters;
mutation during those getters; raw and exact reentry; vector getters; selected-arm
field copying; raw/overapplied callback boundaries; and throwing getters/lengths.
The actual original small edit-distance result remains 2065873279 on both sides.

Exception class, raw message and event order are compared exactly. The rare
noncallable case retains `code.call is not a function` and the event order
`slice`, `get-call`, `env`. Revoked callable Proxies retain
`Cannot perform 'apply' on a proxy that has been revoked`; class constructors
retain `Class constructor Hook cannot be invoked without 'new'`. User-thrown
TypeErrors are not replaced. The receiver/vector identity controls pass for
custom hooks; their own `.call` property is never consulted.

One internal policy change is intentional and recorded separately: an accessor
returning the actual native method now grants exact permission, while the prior
prototype-descriptor policy declined it. Raw invocation remains unprivileged in
both versions. Public values, raw-call behavior and observation order remain the
paired correctness criterion; private diagnostic permission flags are not a
public compiler API.

## Measurement boundary

The gated frozen timing configurations are
`selfhost/build/phase30/inspection-exact-call-plan-01/{screen,confirm}.json`.
They compare unchanged07 against the actual-call candidate on the scalar helper
`bench(128,524800)` and original edit distance `bench(2,0)`. They include the
passing control receipts and use the maintained rotating-process CPU3 protocols.
The clean `exact-call-screen-01` took 199.33 seconds. The helper medians are
0.042825 ms unchanged and 0.043907 ms with actual-call lookup, with roughly
19–21% downward half drift: no helper win is established. Original edit distance
measures 2415.419 ms [2408.571–2477.958] versus 2256.855 ms
[2220.787–2307.646], a 1.070-fold improvement with disjoint ranges. Each timed
sample is one full invocation, so within-sample half drift is unavailable. Keep
this coarse original-program observation separate from a microbenchmark claim.

The original point is too expensive for the standard confirmation's minimum
100-call floor. The [prospective row amendment](../../design/phase30/exact-entry-call-read-row.md)
instead attaches the previously established row32/seed17 complete-state adapter
to the same frozen runtime pair. No row/cell/array code changes. All 28 retained
independent full-array states and 36 ordered row ABI/live-binding observations
pass in `inspection-exact-call-row-controls-01`. The original invocation-control
receipts still cover the byte-identical runtime bodies. Gated cheap screen and
confirmation configs are in `inspection-exact-call-row-plan-01`.

The row screen (`exact-call-row-screen-01`, 4.67 seconds) initially measures
0.437926 ms [0.437531–0.453030] versus 0.689208 ms [0.685411–0.734234], but the
halves drift upward by 27–32% and 167–187%, respectively. It is not a settled
regression claim. Retain it alongside the longer window.

The replacement clean confirmation `exact-call-row-confirm-02` measures
0.334396 ms [0.328746–0.348331] versus 0.306889 ms [0.305796–0.307459], a
1.090-fold observed gain with disjoint ranges. Candidate half drift is at most
1.1%; baseline halves still fall by 7.1–13.7%, so the magnitude is uncertain and
does not establish converged throughput. Confirmation01 is retained separately
as possibly contaminated by a transition overlap; its invalidation receipt
identifies02 as the replacement. No inconvenient result is overwritten.

A future original-program renewal should use an explicit small full-call budget
rather than the microbenchmark floor. The coarse original 1.070-fold screen,
unstable short row, and longer row observation are distinct evidence scopes.

Stable host intrinsics remain part of the existing experiment scope, including
WeakSet and Reflect.apply. The custom-method fallback newly uses Reflect.apply,
so deliberate replacement of that host intrinsic is not claimed transparent.
Public callback method/prototype mutations are explicitly covered by controls.
Function source text and stack-line identity are not preserved promises.

Tools: `inspect-exact-call-read.py` derives the modules and initial configurations;
`inspect-exact-call-controls.mjs` records the focused controls. The pre-existing
`review-scalar-compiler-run.mjs` and `review-scalar-entry.mjs` supply the independent
actual-emission control suites. All evidence directories are retained unchanged.
