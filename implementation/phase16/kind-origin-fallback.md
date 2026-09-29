# Retain the original kind expression for error location

The [design](../../design/phase16/kind-origin-fallback.md) adds one existing
`dg_trace` call around the result of normalizing and checking a datatype kind.
The inner diagnostic keeps priority. The original expression is a fallback
source location when normalization has synthesized an unlocated application.
There is no source search, new helper, new type or change to the checker verdict.

`selfhost/build/phase16/kind-origin-build-01` is built on the validated unbound
binder correction. Genuine checked bootstrap and the unchanged equality
derivative pass the 36-case development gate. `kind-origin-checks-01` is
**6/6 exact**, against two differences in `kind-origin-baseline-01`. Controls
cover the original stuck application, a parameterized kind, a bound return,
an earlier unrelated error and two valid datatype forms. Every reference
acceptance/refusal contract is satisfied.

The adjacent-checkpoint full gate `wave5-frontend-01` passes: **51→48** exact
differences, three newly exact observations and no lost matches. All 2,996
primitive outcomes remain exact. This is not full frontend or release conformance.
