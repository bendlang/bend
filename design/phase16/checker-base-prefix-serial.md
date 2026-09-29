# Phase16 Base-prefix proof: serial whole-source workers

The finite eleven-case law/count gate passed. Whole-source attempt04 was stopped
at roughly4GiB RSS because the harness retained several complete AST results at
once. It is an incomplete probe failure, not an equivalence counterexample.

Run two fresh processes sequentially, full then split, each on CPU1 with4MiB stack
and4GiB heap. Both use identical verified source bytes, checked API, Base cache,
parser/source discovery and raw graph loader. Count named worker entries using
only the already-controlled generated-API instrumentation. No timing claim.

Each worker retains only its own result. Full uses existing f_fresh_defs(raw,1).
Split first verifies Base idempotence, obtains the actual next3413, requires the
exact Base prefix, and uses existing f_fresh_defs(suffix,next). It then prepends
the original Base definitions. Existing f_validate_result and graph freshness
checks run before either freshening route and keep the original order/error.
There is no mutation of the compiler, installed cache or cache format.

Hash the complete book by streaming its canonical JSON definition list, emitting
one definition at a time. Include all nested fields and source intervals, with
no normalization or ignored fields. Retain the exact next counter and errors,
object/term counts and instrumented worker counts. Require equal full-book
SHA256, byte lengths, next and errors. This avoids retaining the full and split
books together or constructing a combined multi-book JSON string. Bind and
verify all inputs before and after both workers. An independent source-only
optimization remains a separate, unapproved experiment.
