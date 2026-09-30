# Independent review of the checked constructor-arm cleanup

Checked16 preserves the reviewed generic runtime15 behavior on three actual
emissions while removing64 implementation lines. It deletes the58-line
constructor-arm admission module (eight functions), its manifest entry and the
five-line generic runtime bridge; two emission lines are replaced. Ordinary
matches use the shared matcher1/lambda path. Scalar Nat loops and trees retain
their registered final worker callback and change only the partial successor
wrapper. Shared arm-type computation remains.

The [prospective source plan](../../design/phase30/retire-arm-prebinding.md)
and unapplied proposal patch preceded root's source integration. Root owns the
source changes and checked builds; this report records independent review and
controls on CPU6. It makes no installation or final conformance claim.

`review-retire-prebind-structure.mjs` verifies each checked source, attempt, API,
runtime, Base and driver receipt. The baseline runtime must contain exactly the
proved generic bridge, and candidate runtime AST must equal baseline after that
one declaration is deleted. For emitted code, it recognizes only the existing
literal-arm and registered-Nat matcher1p patterns, replaces those with matcher1
and fn in an audit AST, and requires complete AST equality. It preserves every
code body and unrelated expression. It is a comparison tool, not a compiler
string postprocessor or semantic normalization escape hatch.

All three structural comparisons pass:

| Actual checked fixture | Ordinary arm sites | Registered Nat wrapper sites | Receipt under selfhost/build/phase30 |
|---|---:|---:|---|
| Complete four-array row |6 |0 |review-retire-structure-16b-row/report.json |
| Mandelbrot helper |0 |1 |review-retire-structure-16b-helper/report.json |
| Original Mandelbrot |2 |3 |review-retire-structure-16b-mandelbrot/report.json |

The first audit invocation parsed the generated suffix independently; Acorn
correctly refused its exports because their runtime declarations were absent
from that isolated fragment. Those three failures and consumed audit bytes remain
at `review-retire-structure-16-{row,helper,mandelbrot}`. The repaired audit parses
and validates each full module first, then selects complete top-level nodes past
the attested runtime boundary. No export check is disabled and no comparison
rule was widened. The16b reports above pass that corrected audit.

Fresh public execution controls also pass:

- `review-retire-scalar-16/report.json`:146 ABI/metadata/coercion/prototype
  observations and72 scalar observations, checked15 versus checked16.
- `review-retire-entry-16/report.json`:nine exact-entry, raw callback, environment
  and slot reentry/restoration observations.
- `review-retire-callables-16-{row,helper,mandelbrot}/report.json`:315,296 and312
  global/selected callback shape observations. Selected mit, hchunk and rcol
  callbacks retain fresh identity, regular-function shape, predecessor bound
  vector and exactCodes registration, inspected only in diagnostic module copies.
- `review-retire-arm-16/report.json`:the retained production j_library synthetic
  arm suite passes72 original and22 exact-arm observations against its original
  reference; all specialized prebinding emission expectations are now false.

The prototype owner separately validates full row states, aliasing and257
ordered public boundaries, and acquires all ten original programs on checked16.
The final selected upstream15 JS gate and remaining primitive/worker/corpus/HVM
integration are separately renewed under the immutable final16 integration plan.
No unrelated large terminal-fuel books are repeated for this deletion-only
admission cleanup.
