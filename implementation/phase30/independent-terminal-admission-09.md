# Independent terminal-region admission checkpoint

Actual checked attempt09 passes 41 synthetic backend admission/refusal books
and 88 execution observations, plus the 22-book/13-execution historical scalar
suite with its explicit planned Nat-helper extension. Seven bounded stress and
neighboring admission books pass their expectations. The lead separately owns
the checked original-program acquisition, full histogram/host controls and
clean measurements.

The tool is `selfhost/tools/performance/phase30/review-terminal-admission.mjs`.
It uses the immutable attempt09 API, runtime, Base and snapshot driver, preserves
each consumed KDef book and emitted module, and does not execute refused cyclic
or malformed books. These are backend controls; source-language acceptance is
not claimed for synthetic KDefs.

`selfhost/build/phase30/review-terminal-admission-09/report.json` records nine
positive books and 32 refusals. Positive cases cover terminal scalar variables
and literals, a scalar Let before the final constructor, Boolean/Nat literals,
an empty terminal Data, nested zero/nonzero countdowns, shared helpers and
completed-helper reuse, dependencies in both owner branches, and a newly admitted
ordinary helper with a native Nat parameter. Full record values are compared
with independent expected field arrays, including U32 wraparound.

Refusals cover record state, record Let RHSs, record-returning ordinary helpers,
record-argument/projection attempts, computed and Let-valued deferred fields,
wrong/short/long constructors, native/template/parameterized/refined owners,
incorrect Data kind, constructor template/native/arity/result mismatches,
erased/dependent/function/record fields, extra constructors, more than 32 fields,
non-tail or wrong-predecessor recursion, self recursion in an argument, mutual
and owner cycles, extra match children and malformed absurd branches.

The initial `review-terminal-bounds-09/report.json` records refusal of a mixed
17-helper dependency depth, 33 completed helpers, and a book intended to exceed
the shared Zero/Succ analysis budget. Each large helper remains below the
individual 8,192-node source bound. That initial receipt establishes refusals,
not an exact measured budget threshold.
The stronger `review-terminal-bounds-09b/report.json` passes seven books. Besides
repeating those three refusals, it admits nearby 15-helper cases, refuses a budget
crossing from the owner's Zero branch into nested-loop analysis, and admits reuse
of previously completed large helpers across that same boundary. Thus a nested
helper cannot evade the shared budget by restarting analysis, and completed-cache
reuse is distinguished from analyzing the same large definitions twice. Both
batches completed without their 45-second external deadlines firing.

Static inspection of the actual original-program emission also records one
redundancy: mit is wrapped in scalarCapture twice after Nat helper signature
admission, while hchunk has one capture. Both captures receive the same newly
constructed ordinary descriptor before it is assigned to G, and record identical
metadata in the private registry. Under the declared standard-intrinsics scope
this adds initialization work without changing descriptor identity or the
guard's reference. It is an explicit cleanup observation, not a failed semantic
gate or a claimed runtime speed difference. Attempt09 evidence preserves those
bytes; the lead owns any later cleanup.

The earlier scalar admission harness now has an explicit
`native-Nat-helpers` profile for this planned signature extension. Its default
retains the old refusal expectation, so historical reruns remain meaningful.
The new profile passes all 22 books and 13 executions in
`review-scalar-compiler-admission-05`; it changes only the expected admission of
the native Nat-parameter helper. These scopes overlap and must not be added into
a frontend or backend-conformance percentage. All reviewer executions are complete
and CPU6 is idle for the lead's next clean timing batch.
