# Independent review of local data elimination

Prospective review, written before the Phase31 local-data candidates are run.
This work owns no production compiler or runtime changes. It tests a bounded
generated-code experiment, not a general proof that arbitrary Bend records can
be flattened. Controlled timings require the campaign owner's separate grant.

## The useful theorem is about demand, not merely allocation

The current `region.bend` restricts intermediate values and helper arguments to
scalars. Its terminal-record exception admits only inert scalar fields. The
closed-array experiment is different: `cell.f4` constructs a `Dp` whose fourth
field performs a deferred `Array.set`. Immutability of the outer record does
not imply purity of field construction, and locality of an array does not
imply that its handle has only one alias.

A private replacement may remove a `Dp` shell when all of the following hold:

1. The shell originates and is consumed within the admitted closed invocation.
   No caller-supplied object, getter, proxy, callback, or saved public bounce
   crosses that boundary.
2. The original constructor's field demands are discharged exactly once, in
   the original left-to-right order, at the original complete demand point.
   Before that point, delayed writes must remain delayed. A returned immutable
   tuple of already demanded field values can stand for the shell internally.
3. The replacement retains the original mutable array handles, including every
   alias. Only the shell and repeated projection/copy machinery disappear.
4. Calls to `arrayfill`, `arrayget`, and `arrayset` preserve their order, U32
   values, indices, modulo semantics, returned handles, and failures. Allocation
   count and order remain unchanged in this first experiment.
5. Every loop iteration uses fresh lexical aliases. The row's zero arm still
   swaps `prev` and `cur`, including when no cell was visited. A later `dp` zero
   arm, by contrast, returns its state without a swap.
6. Original-definition snapshots, exact single-use entry, primitive marker
   refusal, and Array-prototype marker refusal remain active. Public helper
   definitions and unsupported-entry fallback remain byte-identical.

For the exact row, the first three Dp fields are local handles and the fourth
is the write. Under the already declared stable-intrinsics contract and marker
guards, removing repeated marker checks on inert handles might be valid, but
that is a separate demand-elimination step. The first shell experiment should
retain them so that shell removal and forcing removal are not confounded.

## Controls and falsification

The independent harness will consume saved baseline and candidate JavaScript
files with frozen identities. Its oracle implements the row recurrence directly,
without translating the generated helper chain. It compares every slot of all
four arrays at multiple bounded sizes and U32 seeds, not merely a checksum.
Repeated calls must allocate fresh storage. Outputs retain four distinct handle
identities and the expected `prev`/`cur` roles.

Separate instrumented copies record native allocation, reads and writes in
order. Every event includes allocation identity, index and word; operation
order must match both the original baseline and the independently calculated
source schedule. Instrumentation is never used as timing evidence. Its exact
text replacements must assert the unchanged helper bodies before insertion.
Complete event logs are retained for a small selected matrix; broader values
use compact output hashes to limit disk use.

The existing Phase30 independent delayed-demand/alias and native-marker suites
remain useful, but owner executions are not counted as independent runs.
Renewed review will explicitly include raw, forged and constructor callback
results saved across helper replacement; repeated saved-bounce forcing; public
shared handles/backing stores; proxies and foreign array getters; and marker
callbacks that mutate a helper before its later lookup. These controls verify
that a faster private path has not expanded into unsupported public entries.

Two intentionally incorrect semantic witnesses will demonstrate test sensitivity:
an eager fourth-field write before the original demand, and an omitted zero-row
swap. They are retained as expected failures, never timed or promoted. The first
must expose the write through an intervening alias read; the second must differ
in complete role identity even when numeric contents happen to match.

## Compiler rule after the experiment

A useful shared analysis would track three independent facts: value provenance
(scalar, local container, unknown), outstanding demand/effects, and escape.
These must not be compressed into a single `pure` boolean. Constructor creation
can be local while its fields still contain delayed writes; an internal array
can escape through a stored callback even when the root returns a scalar.

Reuse `KTerm`, bounded region traversal, existing exact-entry machinery and
dependency snapshots where possible. Add an explicit plan for demanded local
fields only if the complete-row experiment shows a worthwhile benefit. Admit
canonical native definitions by validated provenance, not their names. Reject
an unknown operation rather than attempting a general ownership or effect
system in this phase. A generated-file prototype alone does not justify
production admission of arbitrary intermediate records or arrays.

## Evidence status

At design time: static review complete; new candidates and independent controls
not executed; no new speed result or compiler promotion claim. Results belong
in `implementation/phase31/local-data-independent-review.md` and raw
`selfhost/build/phase31/review-*` receipts.
