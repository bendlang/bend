# A direct worker for frontend declaration lookup

The new immutable compact-image profile, `compact-profile-02`, records 10,179
samples: `f_find` accounts for 4.00% of weighted exclusive samples, `f_eq` 3.13%,
`dn` 2.86% and `run_loop` 13.26%. The last three also serve unrelated callers;
their percentages are not additive estimates of this opportunity. Profiling
includes startup/hashing and concurrent work, so its wall time is not a speed
comparison. The first launch failed before any compiler request because the new
output parent directory did not exist; its failure is retained separately.

The checked generated `f_find` uses the maintained branch rewrite to return one
`$JMP` record per failed list comparison. `run_loop` dispatches the next step.
Existing `lookup` demonstrates a smaller source alternative: a Boolean-parameter
worker makes the original emitter select a mutual tail loop. Test that pattern
for `f_find` with one worker and no new runtime or generated-code transformation.

Keep the Nil result exactly `KDef{name,"Missing",...}`. A nonempty list extracts
the same head/tail and computes the same `f_eq(name,dn(d))`; the worker matches
True to return `d` and False to continue with `ds`. Do not introduce a cache,
hashing, constructor search, new name normalization or an eager whole-list pass.
The hypothesis is fewer per-comparison trampoline records with identical demand,
definition precedence and missing-result shape. Source size will increase by a
small worker; measure that cost rather than calling this a line reduction.

Use the exact final Phase16 project membership as the parent. Create a separate
source with only `front/declarations.bend` changed and bind all before/after
hashes, source patch, tool and design. Build a genuine checked B1 and unchanged
version5 derivative. Require the existing 36 controls and exact emitted helper
inspection before widening tests.

Direct paired controls must cover empty/missing/first/middle/last names, duplicate
precedence, empty names, Unicode and long common prefixes, plus lazy malformed
head/tail cases and access order. Expose only a named wrapper around the actual
checked helper; retain the complete API as an unchanged prefix and record the
probe extension separately. Compare full result objects and thrown outcomes,
without normalizing existing differences. A found head must not force a bad tail.

If these survive, reuse the full Phase16 frontend no-regression gate and the
original request histories. Compare the exact final source under baseline and
candidate APIs with unchanged runtime/host/Base. Only an exclusive alternating
fresh-process matrix can establish the gain; other compiler/archive jobs must
close first. Keep TypeScript in the same window. No installation until appropriate
backend, helper/host and CLI gates close. Reject the candidate if the cost is
flat, a semantic/demand difference appears, or a larger maintenance burden is
needed to preserve these contracts.
