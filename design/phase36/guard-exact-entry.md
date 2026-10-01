# P36-004: reuse host proof for exact-entry reflection

This is a saved-output experiment, after full-root scoped guard proof. No
production change is authorized by a successful ablation alone.

`invokeExact` first checks private exact-code membership, then inspects the code
prototype, its own `call` descriptor and `Function.prototype.call`. Inside an
active complete-root proof, callees are original guarded definitions or wrappers
freshly created by the closed compiler-generated call graph. Scalar public
inputs cannot inject functions or argument-vector getters into that extent.
The existing host guard establishes standard call and reflection protocols.

Hypothesis: skip only those repeated reflection checks when `regionProof` is
active. Keep `hasExactCodes`, `exactCodes.has(code)`, the original `.call` then
`env` read order, argument-vector identity, exact token install/consume and the
`finally` restoration. Outside the proof, including refused public entry,
delayed bounce/build forcing and suspended Error callbacks, retain every check.

Counterfactual diagnostic counters count exact members and active-proof visits
at already executed branches without calling host APIs again. They are separate
from clean timing modules. If there are few active exact members or original-ray
timing is null, stop. Only a repeatable gain exceeding 3% with preserved public
controls warrants a production proposal. No need to add a new optimizer phase.

The recorded producer consumes an already verified checked-ray control cohort,
preserves its compiler receipts and exact modules, changes only invokeExact and
adds diagnostic counters. The existing colf 57/200 and scope10 assertions run
unchanged on the successor cohort. Actual overflow/reentry uses the unchanged
checked fixture modules with the same tiny runtime ablation; its source/program
bodies remain untouched, and the result is labeled saved-output evidence.

Independent review must challenge external partial wrappers, prototype/call
mutation, getter reentry, host Error callbacks, exceptions and delayed values.
No cache or token is added; this reuses the same bounded dynamic proof.
