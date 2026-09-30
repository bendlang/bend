# Exact complete-state prefix replay, prospective prototype

The initial frozen diagnostic passes all11 output/error/dependency comparisons.
It finds486/486 full-state repeats for an unchanged small request and484/486
for a same-length body or imported-body edit. Signature, length-changing error
and coordinate edits repeat zero full keys. Merkle hashing visits about394,000
objects and makes the instrumented checker take about5seconds; these are
diagnostic costs, not normal throughput or a speed comparison.

Test a cheaper exact key, without weakening it: retain only the previous
request's ordered `check_definition_world` complete inputs and resolved outputs.
At each ordinal, compare the current world, definition and depth against the
previous tuple using iterative exact structural equality. A request-local memo
of object pairs avoids comparing shared subgraphs repeatedly. Reuse only the
contiguous matching prefix; the first mismatch disables reuse for that request.
No name-only lookup or state reconstruction is introduced. World equality still
covers every declaration, origin, specialization memo, fresh allocator and
checked output. Calls' ordinal is an index, never sufficient evidence of a hit.

Cache insertion recursively freezes private plain-data inputs and outputs,
amortized by a WeakSet. Reject functions/non-data objects. The immutable API,
runtime and Base/cache identities remain bound before/after acquisition. Freeze,
exact comparison and cache maintenance belong inside the measured request;
full source discovery and ordinary diagnostics remain unchanged. The saved
generated-code derivative is a prototype, not a compiler implementation release.

Use the initial edit sequence plus original edit-distance unchanged/body-edit/
restoration and Mandelbrot. Compare complete observations and emitted bytes to
actual07 full checking for every request. Retain cached failures as failures;
type/signature/import/origin edits must pass through the same full-check result.
Report checks skipped, equality visits, freeze visits, memory and exact key cost.
No CPU starts before the root releases its other timing window. Correctness
producer limit120seconds CPU2. A clean comparison requires a separately frozen,
granted serial process protocol including startup/warmup and the unchanged
baseline; no ratios from overlapped diagnostic acquisitions. Reject if costs
erase benefits. Production translation would need an explicit private compiler
state interface, independent review and appropriate broader gates.
