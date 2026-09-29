# Phase24 foreign FID control repair and maintained native unit gate

Frozen before these two final control executions. The final production candidate
remains combined-build-02/API7b523bdffc; no production source change is proposed.

The first focused foreign-FID fixture references the IDs of two constant
functions solely from C. Both upstream and candidate remove their callable
segments and then fail C compilation on undefined FID macros. The macro spellings
and artifact paths differ, so the original pair is nonexact (both raw failures).
This is an invalid positive control, not evidence of candidate divergence. Keep
all initial files/results in backend-focused-run-04 and
backend-focused-candidate-04; do not patch generated C or relabel their verdicts.

The new distinct `foreign_fid_v2.bend` makes both functions recursive and invokes
them using an IO-supplied value. Their callable identities must therefore survive
ordinary emission. Keep the existing foreign C macro comparison unchanged and
expect output3 (the inspected IDs differ, yielding1; identity1 plus increment1 is3).
Run the four check/interpreter/JS/native rows under the same final checked image,
30-second limit, 4 MiB stack/4 GiB heap and CPU3–6. If either side still cannot
supply a live FID, stop inventing fixture repairs and report the boundary.

Also execute the exact modified historical native unit script and its scoped
compiler dependencies copied from the frozen candidate into a new minimal tree.
The copy keeps historical build/native-tests and immutable attempt directories
untouched. The existing BEND_BOOTSTRAP override points at a recorded Node wrapper
with the same4MiB/4GiB limits. Run Clang16 with the already captured environment.
Capture the first failure without preemptively changing synthetic AST contracts;
only small confirmed fixture/API maintenance is authorized. No new compiler
source, TypeScript oracle, runtime or timeout change follows from a stale test.

Both runs wait for the coordinator's exclusive cost measurement to complete.
Their results are correctness evidence only; they are not controlled timings.
