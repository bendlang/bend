# Phase24 shared atomic sanitizer witness

The first four generated-program sanitizer controls pass, but the all-operation
fixture performs its atomic updates sequentially. Add the existing upstream
`run/array_atomic_fadd.bend` witness from the saved Phase23
`backend-retained-arrays-01` emissions: its sixteen logical branches share one
buffer, atomically add into cell zero and write disjoint remaining cells.

Compile unchanged reference/candidate C with the same verified sanitizer setup
and run each once with two worker threads pinned to CPU7. Preserve source hashes,
the exact `68` and `2448.25` oracle, every compiler/runtime message and all
failures. This is an additional two-execution concurrency witness, not a claim
of general race freedom or physical multicore stress.
