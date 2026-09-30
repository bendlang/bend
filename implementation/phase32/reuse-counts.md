# Repeated semantic work and exact-state prototypes

The opportunity is real, but a definition-only cache is unsound and the first
complete-state prototype is too expensive. No semantic reuse is installed.

The frozen [counting design](../../design/phase32/reuse-exact-state.md) preserves
the existing Base cache and ordinary actual07 loading/checking/emission. Actual07
API is `d8f609c99b3acef932f90040d0c6152c96605493bef926e46f25559ac125029b`.
The generated API derivative adds diagnostic wrappers only; original source,
driver, Base cache and production compiler are unchanged.

| Request compared with preceding request | Checks | Same definition | Complete-state repeats |
| --- | ---: | ---: | ---: |
| Unchanged small source |486|486|486|
| Same-length body literal edit |486|485|484|
| Length-changing type error |485|484|0|
| Restoration after error |486|484|0|
| Signature edit |486|485|0|
| Source-coordinate shift |486|484|0|
| New imported module |486|484|0|
| Same-length imported-body edit |486|485|484|
| Mandelbrot after different source |504|484|0|
| Edit distance after Mandelbrot |508|484|0|

The checker world contains every visible declaration plus live specialization
memo, fresh allocator and checked outputs. Origins are semantic diagnostic data.
`diagnostic/produce.bend` already explains why a source-only prefix cannot restore
this state. Hashing complete values detects484 reusable Base checks for selected
body edits, while disproving reuse for apparently similar signatures/errors.
There are486 historical complete hits on restoration, but zero against the
immediately preceding failed request; these are different cache policies.

All11 full observation/output comparisons pass. SHA256 Merkle instrumentation
visits393,629–422,815 objects/request; its checker interval is about5–7seconds.
Those are instrumentation costs, not normal compiler speed. Outer acquisition
passes in76.27seconds; process peak RSS456,496KiB. Evidence:
`selfhost/build/phase32/reuse-plan-01/{plan,report}.json` and
`selfhost/build/phase32/reuse-run-01/run.json`; consumed preparation/worker and
exact appended API text are retained alongside the plan.

The [first prefix prototype](../../design/phase32/reuse-prefix-prototype.md)
replaces hashes with exact iterative equality and a memo of compared object
pairs, freezes retained complete inputs/results, and stops replay at the first
mismatch. It passes all15 cases, including original edit-distance body edits
and restoration. But the small body edit still compares361,808 objects:
1,120.5ms equality plus9.4ms new freezing in this diagnostic acquisition.
The unchanged request compares363,023 objects and takes1,708.1ms equality.
These costs motivate rejecting this *per-definition full-world* mechanism.
Cold freezing adds415–1,035ms in selected requests. No clean speed ratio is
claimed from this mixed, warming correctness process.

The combined prefix/compact correctness producer passes30 comparisons in75.88s,
with peak RSS947,784KiB; that peak cannot be assigned to the compact arm alone.
Evidence: `selfhost/build/phase32/reuse-prototype-plan-01/{plan,report}.json` and
`selfhost/build/phase32/reuse-prototype-run-01/run.json`. The
[checkpoint successor](../../design/phase32/reuse-event-checkpoint.md) compares
one complete initial state and explicit future-event dependencies, then resumes
an exact state-bearing event checkpoint. Its outcome remains pending.

After the interruption, its [execution design](../../design/phase32/reuse-memory-bounds.md)
was tightened before running. A fresh checked07 derivative wraps only the event
worker during the ordinary checker export; it excludes all global query
instrumentation. Twenty-two cases run as three independent families of9,6and7
requests, each in fresh baseline/candidate processes with768MiB V8 heaps.
Only the previous request's checkpoints survive; bounds are750,000 equality/
freeze visits and10,000 events per request. The lead additionally supervises
process-tree RSS and available host memory. Prepared raw plan is
`selfhost/build/phase32/reuse-checkpoint-plan-02/plan.json`.

The original prototype's memory peak is evidence for these bounds, not proof
that the session interruption was an OOM. No producer is restarted without the
lead's serialized resource grant. If full-state comparison and snapshot
retention erase the avoided checking work, the mechanism will be rejected
without increasing limits or weakening its key.

The bounded checkpoint investigation is now complete. All22 complete
baseline/candidate observations, dependencies and output hashes agree. Its
54.1s supervised acquisition uses six serial processes, with the largest child
at593,156KiB RSS. The intended phase audit is:

| Family | Observations | Actual coverage |
| --- | ---: | --- |
| Small edits |9|7 successful compilations; type and signature errors reach checking |
| Original programs and edits |6|All6 compile successfully; repeated and body/restoration requests exercise reuse |
| Laws and rejection |7|4 successful law compilations,1 checker error,2 parse refusals |

The duplicate and reordered-law cases are **parse refusals**, before the event
worker. They preserve public outcomes but do not establish event-level duplicate/
order replay correctness. No stronger gate is claimed. The law body edit does
exercise the future-fill schedule proof:485 of487 events are skipped, and the
new body is checked. A failed semantic event has no completed successor
checkpoint and is never skipped. Parse refusals do not replace the prior checked
request's cache entry; all current-world and schedule comparisons still apply
when checking next resumes.

Compared with the rejected per-definition mechanism, event checkpoints reduce
the number of equalities considerably:

| Checkpoint request | Events skipped | Objects compared | Key interval ms | Newly frozen objects |
| --- | ---: | ---: | ---: | ---: |
| Unchanged small |486|95,485|212.47|4|
| Small body edit |484|95,425|186.33|1,506|
| Unchanged original edit distance |508|99,046|140.83|4|
| Original edit-distance body edit |486|96,899|169.60|20,670|
| Law body edit |485|95,390|193.52|1,862|

This remains an expensive state representation. Complete misses freeze roughly
448,000–481,000 objects; observed full-miss freezing intervals range168–467ms.
Some intervals include pauses: one interval freezing only four new objects takes
306ms, so interval duration cannot be attributed solely to the counted operations.
Most error/signature/coordinate changes reuse zero events and retain this
maintenance work. The same-length edits save checking, but these serial warming
correctness sequences do **not** establish a clean speed ratio.

**Decision:** do not promote full-world checkpoint retention. The feasibility
result supports the dependency-complete event proof, but the measured comparison/
retention costs and new stateful interface do not justify production integration.
No additional timing or memory-limit increase is needed for that decision.
Evidence is `selfhost/build/phase32/reuse-checkpoint-correctness-02/report.json`.

This is not a rejection of incremental checking in general. A separate future
experiment could use the existing private persistent parse/check inspector,
whose immutable decoded Base identities survive between edits. These normal
library requests decode Base afresh. Dependency tracking or stable node identities
could avoid traversing the complete state, but neither is implemented or measured
here. Public host mutation and precise invalidation would still need proof.
