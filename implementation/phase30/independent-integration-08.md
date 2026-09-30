# Independent lexical-helper compiler checkpoint

The actual checked lexical-only attempt08 passes the independent admission,
execution, entry and name-identity controls. This transfers the earlier
generated-output spelling experiment into the compiler without changing region
admission or runtime. Performance transfer is measured separately by the lead.

All executions use attempt08's immutable API, runtime, Base and snapshot driver.
The working compiler sources already contain a subsequent terminal-region
experiment; those live sources are not inputs to this checkpoint.

| Suite | Result | Raw directory under selfhost/build/phase30 |
| --- | --- | --- |
| Actual j_library admission/refusal | 22 books, 13 executions pass | review-scalar-compiler-admission-04 |
| Actual08 versus actual07 ABI, effects and prototype observations | 146 comparisons pass | review-scalar-compiler-run-05 |
| Independent arithmetic/long-loop oracle | 72 observations pass | review-scalar-compiler-run-05 |
| Exact entry/reentrancy/cleanup | Nine observations pass | review-scalar-entry-04 |
| Checked name fixture acquisition | Checked status ok; emitted module retained | review-lexical-source-08 |
| Actual backend lexical identities | 18 names, 15 loop executions and public exports pass | review-lexical-names-08b |
| Checked name fixture numeric oracle | 45 points pass, including 50,000 iterations | review-lexical-names-08b |

The synthetic name book puts helpers after their caller and distinguishes case,
dot/slash/underscore/digits, reserved and prototype-like words, composed and
decomposed Unicode, and an astral character. It checks generated private function
declarations and absence of private dictionary calls. These are actual backend
observations on synthetic KDefs, not source-language acceptance claims. The
separate checked Bend fixture uses step, Step, step_1 and step1; its emission
receipt establishes source acceptance and compiler identity before execution.

The initial synthetic fixture omitted the native Bool owner required by the
existing U32 provenance predicate. The compiler correctly declined the worker,
and the control's expected-admission assertion failed. That receipt and consumed
tool remain in `review-lexical-names-08`. Adding the missing fixture owner, with
no production edit, produces the passing `08b` run. This is a test-fixture repair,
not evidence of a compiler defect or a weakened ownership check.

Static source review confirms that only private declarations and JCall spelling
change. Delimited decimal codepoints form injective names without a symbol table,
and retain original source names for type lookup and public guards. Private
function declarations live in the same definition IIFE; forward references are
ready before any public call. Public descriptors and callback lifetime remain
unchanged. All 146 same-runtime observations include the sixteen ambient-prototype
cases; the separate historical preworker prototype limitation remains as reported
in the attempt07 checkpoint.

No clean timing, compiler promotion, commit or push was performed by the reviewer.
