# Exact-arm retry with corrected callback entry

The generated-output retry repairs all three historical outer-application
counterexamples and passes its focused field, result, entry and callback-shape
controls. New clean timing finds a 27.88% regression, so this retry is not a
profitable compiler change. Production admission still uses the strict
count-less-than-total rule; the earlier rejected attempt and its measurements
remain unchanged.

The prospective plan is
[exact-constructor-arms-retry.md](../../design/phase30/exact-constructor-arms-retry.md).
The retry consumes checked attempt07's original edit-distance output and its
corrected matcher1p runtime. It replaces only five cell/cell.f1–f4 literal-arm
prefixes with matcher1p where field count equals arm arity. Runtime, projections,
array operations, primitive expressions, call sites and arm bodies retain their
original bytes. This is a disposable generated-output intervention, not a new
compiler image.

| Unwrapped module | Bytes | SHA-256 |
| --- | ---: | --- |
| Corrected unchanged output | 82,469 | 7b0d5eb670693d0940155a1e560da81c9d8b98e07f01376264bccb20ba67361c |
| Five exact-arm replacements | 82,484 | 2791ca4f6710542518c3580be00d4d9fa43839a20ea43129a498d7aae6797597 |

Fresh evidence under `selfhost/build/phase30/`:

- `review-exact-arm-retry-01`: frozen source/plan/derivation, unchanged and
  modified modules, identical complete-row wrappers, 28 independent oracle
  points and prospective screen/confirmation configurations. Its
  `row-controls.json` records all 56 complete four-array comparisons passing.
- `review-exact-arm-retry-outer-01`: all three original witnesses pass in
  repaired mode, preserving plain order, throwing copied-length behavior and
  callee replacement at the outer application boundary.
- `review-exact-arm-retry-fields-01`: 33 foreign field-vector/copy/effect/error
  observations pass through the public call path. Its legacy limitation section
  also records that ordinary G.cell replacement has equal behavior here.
- `review-exact-arm-retry-entry-01`: seven ordered exact/raw/hooked/overapplied
  prebinding scopes pass against the same immutable attempt07 runtime.
- `review-exact-arm-retry-shape-01`: 20 public observations cover all five
  matchers' arity/environment/bound fields, anonymous arrow shape and
  nonconstructibility, independently mutable fresh callbacks, raw bounce return,
  attempted extra-argument permission forgery and call-hook return observation.

The historical bug was eager arm execution during an enclosing oversaturated
callback. Corrected matcher1p grants permission only on exact application; other
entry paths return the original unsliced-field bounce. The retained witnesses
now demonstrate that no body effect overtakes the caller's later length read.
The old 1.023× result does not measure this registered-callback implementation and
must not be reused.

The timing owner ran the frozen complete-row `[32,17]` point under the parent's
exclusive CPU3 grant. `exact-arm-retry-screen-01` records unchanged median
0.392811 ms (range 0.391220–0.393309) and exact-arm median 0.536097 ms
(0.532752–0.536846). The exact-arm halves improved 14.7–15.4%, so this short
window was insufficient by itself. The unchanged halves differed by at most
1.92%.

`exact-arm-retry-confirm-01` records unchanged median **0.335203 ms**
(0.330210–0.348095) and exact-arm median **0.428672 ms**
(0.419513–0.435055), a **27.88% slowdown** with disjoint sample ranges. The
unchanged halves still improved 6.9–12.9%; the exact variant had four half-drift
magnitudes at most 3.83% and one 6.01%. The 42.20-second outer run is experiment
wall time, not an invocation measurement.

The independent recommendation is to close this retry without widening compiler
admission. It demonstrates the semantic value of the entry repair, while also
showing that a superficially smaller administrative path is not necessarily
faster after that repair. It does not isolate the individual costs of callback
registration, dispatch or host optimization, and does not justify adding another
runtime fast path merely to recover the old small gain.
