# Phase24 independent profile and source review

Initial read-only assessment; no compiler changes or performance jobs were run
by this reviewer. Scope: the installed Phase23 source, emitted API, maintained
profiling tools and the root owner's fresh CPU profile. Read `AGENTS.md`, the
experiment workflow/current steering/frontier and the checked-B1 development
workflow before proposing experiments. The candidate lookup review and direct controls are recorded below. Allocation
interpretation and final promotion remain separate decisions.

## What the current CPU profile establishes

`selfhost/build/phase24/cpu-profile-02/report.json` is complete with unchanged
captured inputs and the expected accepted-types/unsafe-proof-refusal result.
It uses the final Phase23 API on the frozen ordinary compiler workload.
Top-level spans are about 5.019 s in `f_complete_source`, 3.343 s in
`check_program_diagnostic`, 0.360 s in `f_graph_trace`, and 0.463 s combined in
`driver_report`/`driver_bad_names`. The 10.014 s sampled window attributes
0.624 s to `f_find`, 0.532 s to host `validateSpanBook`, 0.295 s to
`index_remove`, 0.189 s to `lookup` and 0.171 s to `index_find` as exclusive
function samples. Runtime dispatch (1.730 s) and GC (0.879 s) are shared costs,
not additional savings assignable to each source hypothesis.

This favors frontend lookup and host validation over another graph-conversion
rewrite. These are instrumented diagnostic observations after Base preparation
and dependency discovery, not fresh-process benchmark values or invocation
counts. The first CPU attempt retained useful samples but failed an outdated
success assertion; it remains a failed attempt. The first allocation attempt
failed JSON serialization with `RangeError: Invalid string length`; it supplies
no completed allocation result.

## First candidate: avoid redundant declaration searches

The current frontend already carries `FParseScope.index`. However, blanket
replacement of `f_find(name, prior)` by its indexed lookup is incorrect:
`f_source_body` initializes the index with `index_build(reverse(prior))`, which
selects the last initial event, whereas `f_find` returns the first. The retained
Phase22 template-index controls explicitly distinguish same-count/different
whole definitions, different-count private duplicates and missing sentinels.
That earlier change proved only the template-count projection.

Incremental `f_context_declared` does prepend the same new header and
`index_set` it, so newly published entries agree. ADT-only consumers in family,
marked-name and do-header handling may permit a stronger projection because
valid datatype names cannot be law-filled. Before using that observation, check
kind, arity, leading quantities and Missing-versus-Absent behavior, including
supplied completed sources. Do not infer whole-definition equivalence from the
old template-count proof.

Many remaining `f_find` calls instead search the current raw local `book`:
definition base/signature/body, law/type freshness, `f_decl_find` and
`f_decl_taken`. The profile needs physical caller attribution or bounded counts
to decide whether these dominate; the prior-book projection alone may miss the
actual hot path. A potentially smaller experiment uses indexed *absence* to
skip local scans: every ordinary published local header also enters scope.index,
so a validated absence can establish no matching local declaration while index
hits keep legacy first-visible lookup. Prove raw-to-qualified/aliased name
mapping, temporary self headers and import fills before changing this path.
`f_decl_taken` already checks both raw and namespace-qualified indexed keys in
addition to a local linear search, making its redundant responsibility a useful
first proof target.

Smallest falsifiers: an initial law/fill pair with different full payloads;
same-count duplicate definitions; qualified/unqualified collisions; an alias
whose target exists alongside the raw name; an imported fill; a local constructor
masking a far law; a provisional self header before body publication; and an
absent name. Preserve the exact first error and raw diagnostics. Existing
Phase22 template/header/constructor controls are relevant, but must bind a newly
checked candidate if the source changes.

## Other source leads, presently lower priority

- `uses_merge` reads `uses_get(b,id)` and then filters `uses_del(b,id)` for every
  element of `a`. One traversal could return the first quantity and the filtered
  list, reusing the existing list representation. It must still remove every
  duplicate from `b`, preserve retained order and preserve first-value selection.
  Require meaningful sampled cost/list lengths before spending an edit on it.
- `norm_exact_head` counts both child-list lengths before the worklist visits
  those children. The emitted API evaluates these operands even on a tag mismatch.
  A guarded head comparison or parent-preserving zipper could reduce wasted work,
  but flattening child worklists without preserving arity is unsound: differently
  parenthesized trees can share the same preorder. Keep literal payloads and
  names/quantities/cell contents exact. Current samples do not rank this first.
- Contextual materialization traverses/rebuilds children in higher/lower stages.
  These stages preserve eager/deferred error and beta-reduction order. Its direct
  sampled cost is much smaller than lookup; count unchanged reconstructions
  before proposing fusion or another term representation. Retain Phase22's
  discarded-lambda, delayed-body and alias-before-argument counterexamples.

Do not repeat already completed Phase17 direct-find dispatch or Phase22
full-filter worker changes. They are present in the source. Existing fresh-bound
state also makes a new global maximum-ID cache an unjustified first choice.

## Profiling tool interpretation

The existing Phase22 owner tools attribute anonymous generated functions by
source location and retain signed CPU deltas. Their physical callers can lose
trampoline tail ancestry; owner/self and caller views are alternative
attributions, not additive costs. If used for Phase24, verify the profile API URL
matches the exact generated API path before attributing enclosing owners.

The new Phase24 sampler wraps exported methods after priming and records API
spans. CPU/performance clocks are aligned with a measured start uncertainty;
near-boundary phase labels are approximate. `byApi` fractions use the complete
profile denominator, not a per-phase denominator. CPU samples do not measure
allocated bytes, live memory or function invocation counts. Candidate speed
claims require the separate exclusive, uninstrumented same-input matrix.

The sampler captures API/Base/runtime/source and direct helper hashes. Its
captured-input list does not yet explicitly identify the consumed Base-cache
file or the driver's compiler.json. The driver validates its cache, and the
immutable attempt provides other lineage, but a future closed profiling receipt
should bind those dependencies rather than overstate this report's closure.

## Reviewed local-guard candidate and contract controls

The root-owned `local-build-01` passes its genuinely checked build and maintained
36 strict focused observations (root-owned evidence). Reviewed candidate API:
`bcfe7b9d537c27824c48566c3a38b769dda0baa6c1ea9e306523e11a8a7dda36`.
The production diff adds one `f_decl_local` helper, propagates `scope` to
`f_def_signature` and replaces only the raw local-book searches. Prior-book,
constructor, namespace and alias semantic owners remain unchanged.

The helper implements the smaller negative-only guard: map the queried raw name
exactly as `f_context_header` does; an absent indexed key searches Nil to preserve
the named Missing sentinel; a present key invokes the unchanged local `f_find`.
No index payload substitutes for a raw definition.

The producer invariant holds inductively for the inspected call paths:

1. `f_body_header` and header parsing begin with an empty local book, so initial
   prior-index ordering cannot invalidate local absence.
2. `f_context_publish` prepends the same raw definition and calls
   `f_context_declare`, inserting its mapped top-level name into the index.
   Exact-key insertion retains other keys, including complete hash collisions.
3. Namespace and alias mappings stay fixed within that source. Provisional
   definition/type headers only add or replace indexed entries; they can cause
   extra scans, never a false absence.
4. The only import routes resetting scope require an empty local book;
   `f_import_leading` rejects imports after a declaration. Decorators preserve
   the passed scope. Completed supplied sources return their parsed value
   directly instead of entering these parsing call sites.
5. Constructors use their separate index and are not substituted for top-level
   raw definitions. Aliases mapping different raw names to one key, duplicate
   law/fill events and reversed initial-prior winners cause conservative hits;
   the retained local search determines the original result.

The independent private wrapper preserves the complete candidate API prefix and
adds diagnostic exports only. It is explicitly not a checked release API.
`local-guard-controls-01` passes21 named controls and567 exact local-lookup
comparisons across63 publication states. Controls exercise empty/missing names,
raw versus qualified names, dotted module names, alias precedence, colliding
alias keys, prior-only hits, opposite initial winners, local duplicate/fill
ordering, a temporary self header, constructor-only membership, and the actual
FNV collision `costarring`/`liquid`. An inconsistent private state containing a
local definition but an empty index intentionally differs and is retained.
Thus the claim is tied to parser-produced states, not arbitrary foreign objects
or inconsistent hand-constructed scopes.

Command (CPU1, Node24, 4MiB stack,512MiB heap):

```sh
taskset -c 1 /home/ai/.nvm/versions/node/v24.18.0/bin/node \
  --stack-size=4096 --max-old-space-size=512 \
  selfhost/tools/performance/phase24/local-guard-controls.mjs \
  selfhost/build/phase24/local-build-01/equality/api.mjs \
  selfhost/build/phase24/local-guard-controls-01
```

No source correctness blocker was found within that invariant. The separate
public frontend/chronology gates and exclusive uninstrumented performance matrix
still determine promotion. The direct controls are not an end-to-end speed or
universal frontend-conformance claim.

Control report SHA256: `fe1291984f781bdc6284ba17aa4c6932a6361829ec81412aa2a62054a4e72785`.

Consumed control tool SHA256: `fd20c0b5bb490b9b1f8117747ff29b47a989cd44d24dde7ee08e0fe59a70daa9`.

## Completed allocation profile interpretation

The root-owned `allocation-profile-02` succeeds with a 1MiB sampling interval,
including objects collected by major/minor GC. It aggregates exact call-frame
`selfSize` estimates and retains sample records, rather than serializing the
failed attempt's very large complete allocation tree. The estimate is neither
retained heap nor an exhaustive allocation count. Physical call ancestry lost
from this aggregation cannot be reconstructed from its summary.

The summed sampled-size estimate is 9,296,244,808 bytes. Exact named frames account
`$has_name$` 465,592,736 bytes (5.01%), `$index_remove$` 361,767,168 bytes (3.89%), `$missing$` 331,428,552 bytes (3.57%).
Anonymous frames also belong to their enclosing generated functions; grouping
those by exact source location is a separate attribution, not extra allocation.
The earlier low CPU ranking of materialization therefore does not establish low
allocation cost, but semantic stage fusion still needs its own invariant.

`has_name` is the next small source candidate after the local guard: its miss
branch still returns through `kc`, while Phase17/22's direct Bool-worker pattern
is already established for analogous searches. Preserve empty-list false,
first-match short circuit, exact strings (including empty/Unicode), missing-name
full-tail demand and bounded deep-list stack behavior. First inspect emitted
code and run direct parent/candidate controls; only an uninstrumented isolated
ablation can establish a gain. Do not credit the entire sampled allocation share
as time saved.

Allocation sampling currently stops after CPU profiling stops and its JSON is
serialized/written. The total therefore includes profiler/reporting allocation
(the retained samples visibly include a roughly24.8MB CPU JSON allocation).
Describe it as the diagnostic sampled window rather than solely compiler
allocation. This does not invalidate ranking compiler-owned frames.

## Local-only cost screen review

Independent read-only inspection of `cost-01/report.json` finds all nine rows
healthy and their captured input identities stable. Three fresh processes per
variant run in the recorded order TS/released/local/local/released/TS/released/
TS/local on CPU0. Same frozen source, pin, Base, runtime and typed adapter are
used; each Bend image uses its validated image-specific cache. The unchanged
measurement harness compares full ordinary observations with validated actual
host provenance. No emission occurs and OS caches are not flushed.

Released process times are11.4127–11.4514 s; local-only candidate times are
11.1937–11.3458 s. Released request times are10.2990–10.3379 s; candidate request
times are10.0864–10.2296 s. Both ranges are separated in this acquisition.
Mean improvements are1.50% process and1.58% request; peak RSS falls1.47%.
This supports a small benefit on this screen, not a statistical population bound.
The same-window TypeScript ratio improves from3.2339× to3.1854×. Phase23's older
3.10× ratio came from a different window and must not be used to infer a
regression or multiplied into a speedup.

This is the local-only candidate, not the pending combined membership/backend
image. It cannot establish that later additions retain the same cost.

Cost report SHA256: `e950a3d01574cfc1732e10f8073de1b5d5bf631ca6b9612567ed19b29766b7ed`.

## Direct membership branch: source review pending candidate controls

The P24-004 source diff changes only the `has_name` Con case: bind
`String.eq(h,name)` once, match the resulting Bool, return True on a hit and
recur on a miss. It adds three lines and no helper/type/representation. Source
value semantics and first-match termination are unchanged for finite valid
lists. The forthcoming paired tool also checks finite malformed-tail demand,
Unicode/surrogate strings and deep lists; generated output and measured cost
remain to be reviewed on the combined checked image.

## Membership worker: completed source/generated-code review and controls

The first source form above failed its genuine checked build: Bend forbids
matching the proposed computed local binding directly. `membership-build-01`
remains a failed attempt. The frozen follow-up moves that same Bool into a worker
parameter. The final diff adds six physical lines and one helper,
`has_name_next(rest,name,same)`; no datatype or law is added. The original
`has_name` calls it after evaluating String.eq once, and the worker returns True
or tail-calls `has_name` on the rest.

Reviewed checked/derived candidate `membership-build-02` API:
`9c3c02bb8276b656557c7c06d440dc3df89bb4dd22a6ef4d81de2ca37167e0b7`.
The root-owned build and36 strict focused observations pass. The emitted
`has_name` and `has_name_next` functions each use a two-state `for`/`switch` loop:
read one Con head/tail, evaluate String.eq once, then return True or continue.
There are no per-miss Unit branch closures or trampoline messages in these
workers. This confirms the intended lowering, not an end-to-end gain.

Independent `membership-controls-01` compares that candidate with the local-only
API `bcfe7b9d`, holding the earlier lookup change fixed. All18 named examples,
1,152 deterministic membership cases,15 deep probes and7 paired demand/error
controls pass. Deep probes reach10,000 cells with first/last hits and complete
misses under the existing4MiB stack. String cases include empty strings, embedded
NUL, prefixes, ordinary Unicode, astral characters, non-normalized spellings and
lone high/low surrogates. Demand controls compare getter access order and error
name/message exactly, including first/second hits before a malformed tail,
missing queries that demand it, Nil field non-demand and root head/tail errors.
This is finite raw-object coverage, not a claim for all foreign JavaScript
objects or general stack safety.

The tool appends private unchecked diagnostic exports to unchanged API prefixes;
no release API is modified. It runs on CPU1 with512MiB heap and finishes in an
observed0.48 s; that duration is not a membership performance measurement.
No source correctness blocker was found. Later combined images and final
controlled cost remain separate gates.

```sh
taskset -c 1 /home/ai/.nvm/versions/node/v24.18.0/bin/node \
  --stack-size=4096 --max-old-space-size=512 \
  selfhost/tools/performance/phase24/membership-controls.mjs \
  selfhost/build/phase24/local-build-01/equality/api.mjs \
  selfhost/build/phase24/membership-build-02/equality/api.mjs \
  selfhost/build/phase24/membership-controls-01
```

Membership report SHA256: `581d6470299fe828a84ee2a341cf25018cacfa173dda32a3b9af145431647755`.

Consumed membership tool SHA256: `5025b38de05cfbbf28b6ed038f907ba74a700951c14f943206bf0a9df786ae7b`.

## Final measurement closure

The separate [final measurement review](measurement-review.md) reviews all15
rows of cost-02 on final combined02. It records the4.89% process/5.58% request
improvement versus the same-window release, essentially unchanged peak RSS,
and2.9854× TypeScript ratio, including the0.64% integration cost versus the
membership-only image. The reviewed helper source bytes are unchanged in that
final snapshot. No instrumented-profile timing is used as a speed claim.
