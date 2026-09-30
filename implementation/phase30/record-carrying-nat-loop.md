# Opaque state in private Nat loops

Agent-generated investigation, following the frozen
[design](../../design/phase30/record-carrying-nat-loop.md). No compiler source was
edited. The disposable row-loop output passes 140 complete four-array oracle
observations and initially 32 ordered ABI observations. Independent static review
finds an additional raw predecessor coercion gap, repaired in 02; 02 passes all 140
states and 33 ABI observations. A subsequent guarded variant passes 196 complete
states, 36 inherited boundaries and 60 live-binding controls. Independent static
review finds no further blocker in the declared scope. Longer-warm timing finds
only a 1.109–1.110× gain once live-binding guards are included. No general compiler
implementation is proposed yet.

## What the scalar restriction does

The current `j_nat_loop_signature` accepts only primitive Nat/U32/F32/Bool
carried arguments and results. Nothing in local-slot assignment itself depends
on that representation: an Array or closed record can remain opaque, with fresh
immutable aliases each iteration. `gen`, `init`, and `dp` already have the
required explicit live telescopes in both arms, so they are plausible type-only
extensions. A bounded closed-type admission can avoid traversing record fields;
its job is to reject unresolved/dependent/erased/function/IO shapes, not prove
effects from scalar-looking types.

`row` requires a second change. Its zero arm has two explicit lambdas followed
by a Dp match, while the successor arm has four explicit lambdas. The current
zero-count equality rejects it even after widening types. Calling the original
residual zero matcher preserves the demand boundary. Feeding the entire state
through the existing `j_lambda_code` terminal path without accounting for the
residual argument would be incorrect.

The successor's explicit telescope matters more than the carried value's type:
removing an intermediate match or helper evaluation could reorder demands with
later argument expressions. Erased arguments, lifted lambdas, unknown types,
dependent families, unbounded inspection and unsupported zero residuals should
remain refusals. Existing scalar-region planning already rejects non-scalar
parameter types; widening loop admission must preserve that separation.

## An actual scheduling obstacle

A public successor callback originally executes one iteration and returns a
bounce. Generic `apply` may then inspect a custom copied vector's length before
forcing that bounce. An eager local loop performs subsequent cell effects too
early. This is observable through oversaturation even when all normal program
results agree. It also changes how many effects happen before a caller explicitly
forces a returned raw bounce. Scalar types do not rule this out: a referenced
helper may be replaced with an effectful descriptor.

The prototype preserves the public first step and returns a private worker
bounce for later iterations. That private worker receives an ordinary fresh
argument array and loops internally. Its terminal step creates the original
zero continuation before the final cell expression and returns a bounce into
that continuation. Dp projection, constructor scheduling, foreign field-vector
handling, partial descriptors and array identity remain on their old paths.
The returned raw bounce's internal target is different; only deferral behavior,
not byte identity of private bounce objects, is claimed.

The scope assumes an immutable recursive `G.row` descriptor. A retained test
changes `G.row` during the first cell: baseline observes the replacement at
remaining count2, whereas the prototype reaches remaining count0. This forbids
promoting the artifact unchanged. Any production extension must preserve live
lookup and descriptor changes at the recursive demand boundary, or establish
a separately authorized immutable binding contract. No such contract exists.

## Acquisitions and checks

`selfhost/build/phase30/prototype-record-loop-01` contains original Phase29,
row-loop-only, corrected private-cell-only, private-cell-plus-row-loop and pinned
TypeScript modules. It also retains a deliberately eager rejected variant used
only for boundary counterexamples. Every changed byte, consumed derivative tool,
frozen design and input identity is saved. No Array/cell/project/build helper is
rewritten by the row-loop ablation.

The 28 independent row states are checked in each of five variants: n=0,1,2,7,
16,32,64 and seed=0,1,17,4294967295. All 140 pass. The 32 ABI observations compare
zero/one/many steps, frozen/foreign/getter/proxy/short/copied field vectors,
throwing cells, changing live `G.cell`, public partials, raw bounce deferral and
oversaturation. All pass. Three counterexamples are required to differ: eager
cold scheduling, eager raw-bounce forcing, and mutable recursive G outside scope.

The first controls launch fails to parse because of a parenthesis in the new
test harness. Its stderr and exact consumed bytes survive in
`prototype-record-loop-controls-launch-01` and
`prototype-record-loop-controls-syntax-01.mjs`; no implementation result follows
from it. Corrected controls are in `prototype-record-loop-controls-02`, with an
independent launcher receipt. Acquisitions use CPU6, Node24.18.0, 4MiB stack and
1GiB heap; durations are descriptive, not compiler or generated-program speed.

## Mechanism counts

Separate instrumentation runs ten full row32seed17 calls:

| Runtime site | Original | Row loop | Private cell | Both |
|---|---:|---:|---:|---:|
| Generic applications | 10,930 | 9,430 | 6,130 | 4,630 |
| Function descriptors | 5,800 | 4,600 | 2,600 | 1,400 |
| Bound descriptors | 950 | 50 | 950 | 50 |
| Non-tail calls | 5,770 | 4,870 | 3,850 | 2,950 |
| Jumps | 5,160 | 4,560 | 2,280 | 1,680 |
| Apply-copied slots | 26,330 | 23,030 | 12,890 | 9,590 |
| Prebinding-copied slots | 320 | 20 | 320 | 20 |
| Private projection copies | 0 | 0 | 3,840 | 3,840 |
| Projection entries | 2,590 | 2,290 | 2,590 | 2,290 |
| Builds | 330 | 330 | 330 | 330 |
| Array reads / writes | 1,280 / 320 | 1,280 / 320 | 1,280 / 320 | 1,280 / 320 |

The row loop removes 1,500 generic applications, including 900 bound descriptors,
and 300 repeated native Nat projections; record/tuple projection bodies stay
unchanged. After the private-cell improvement that is 24.5% fewer applications.
These are named operation counts, not time shares, total allocation, or speed.

Frozen five-way screen/confirmation configs are ready. No clean timing has run.
The next decision requires independent scheduling review, a parent timing grant,
and resolution of live recursive descriptor mutation before a compiler patch.

## Independent raw-callback review and repaired02

The independent reviewer supports the deferred scheduling shape for primitive
BigInt predecessor slots but identifies one further boundary: a raw successor
callback can receive an object with `Symbol.toPrimitive` in its predecessor
slot. The original recursive prefix coerces it while creating its next public
descriptor. Prototype01 discards that descriptor and passes the original object
to its worker, causing a second coercion. This is preserved as a failing
differential observation in `prototype-record-loop-raw-01`, after a frozen
[boundary amendment](../../design/phase30/record-loop-boundary-amendment.md).

Prototype02 requires `typeof predecessor === "bigint"` for private transfer;
all other values return the original already-computed bounce. It repeats neither
arguments nor projection. All 140 complete states and the extended 33 ABI
observations pass in `prototype-record-loop-check-02` and
`prototype-record-loop-controls-03`, with three intentional counterexamples still
retained. The previous operation counts belong to01; no fresh02 counters or
timings are inferred. Independent static review finds no remaining blocker in
the declared native-BigInt/immutable-recursive-G scope.

Five-way02 timing configs are frozen but unexecuted. The optional per-iteration
captured-target guard is only a prospective idea; no guarded output or compiler
implementation has been created. The guard must precede next argument evaluation
and preserve the already captured target on fallback. Array-call results elsewhere
in this phase show why its runtime cost cannot be assumed small.

## Subsequent live-binding guarded ablation

Following a new parent task and the frozen
[live-binding plan](../../design/phase30/record-loop-live-binding-guard.md),
`prototype-record-loop-guard-01` adds separately identifiable guarded modules.
Earlier fixed-global outputs and their failing mutation witness remain unchanged.
The guarded output captures each recursive G target before next argument
expressions and checks its ordinary original descriptor without invoking new
accessors. Changed bindings or internals use the already captured target through
the original prefix and tail bounce. A current callback retains its previously
selected body; mutation changes the following call at the same point as before.

The first public iteration also checks its captured target. This matters when a
caller retains an old public partial and then replaces G before invoking it.
Non-BigInt raw predecessors retain the original already-computed bounce. Array,
cell, record construction/projection, lexical aliases and the final residual Zero
matcher are unchanged. The private-cell combined context still has its separate
immutable cell-chain limitation; adding a row guard does not remove that limit.

All 196 complete states (28 points in seven modules) pass. The prior control suite
passes 36 observations, now requiring formerly failing live G replacements to
match at three mutation points. Two deliberately eager scheduling witnesses remain
required to differ. Sixty additional differential controls cover G replacement,
zero-arity initializers, G getters, code/arity/env/bound changes and accessors,
bound-array mutation, io/type metadata, code.call hooks and descriptor prototypes.
They test raw entry, first/second-cell mutation, outer copied-length mutation and
index coercion. These controls are authored with the prototype; independent
review is still required before timing.

The first new live-binding controls run stops after 55 passing observations
because the harness compares fresh `Symbol.toPrimitive` function identities inside
two event objects. Its saved JSON transcripts agree. The corrected harness records
whether each raw index remains the same object within its own execution, without
coercing it; all 60 observations then pass. Both attempts and exact consumed tools
survive as `prototype-record-loop-guard-live-01` and `-02`. This is a test-harness
correction, not a compiler or generated-code repair.

Fresh guarded counters match the fixed-loop table on normal inputs: generic
applications 10,930→9,430, or 6,130→4,630 after private cells; bound descriptors
950→50. Guard descriptor inspections and their host allocations are outside those
counters. They cannot establish a speed gain. Frozen seven-way screen/confirmation
configs exist but are unexecuted. No production compiler or runtime file was
changed by this record-loop investigation.

An independent analysis agent then reviews the exact guarded output and finds
no new blocker under stable host intrinsics. The review checks lookup-before-args,
previous-prefix callback selection, unchanged zero ordering, captured fallback
and the raw BigInt guard. It supplies no additional dynamic-test claim. The
review also identifies an integration condition: these prototypes preserve the
saved Phase29 runtime, including its subsequently discovered historical
`matcher1p` scheduling behavior. A production port must use the repaired
`exactCode` boundary and compare against the pre-prebinding reference, as well as
these saved outputs. The new exact-entry capability could keep the original
generic body for all raw/oversaturated/hooked entries; that is a future general
implementation direction, not a measured change in this artifact.

## Clean timing: guards retain only a modest gain

After the independent review, the lead grants exclusive CPU3 timing for the
frozen seven-way screen and confirmation. All expected full-state outputs match.
Exact process outputs and outer launcher receipts survive in `record-loop-screen-01`
and `record-loop-confirm-01`. No input or comparison variant is retuned between
windows; the guarded variants are compared with their own cell context.

| Row / cell path | Short median ms | Longer-warm median ms |
|---|---:|---:|
| Original | 0.710426 | 0.279911 |
| Fixed row loop | 0.699657 | 0.224699 |
| Guarded row loop | 0.604644 | 0.252509 |
| Private cell | 0.306153 | 0.204368 |
| Private cell + fixed row | 0.240539 | 0.150644 |
| Private cell + guarded row | 0.293509 | 0.184066 |
| Pinned TypeScript | 0.024539 | 0.022956 |

With the ordinary cell, the fixed row loop improves 1.246×, while preserving live
recursive binding changes leaves 1.109×. With private cells, the corresponding
incremental gains are 1.357× and 1.110×. The guarded gains have disjoint five-sample
ranges. The combined private-cell/guarded-row artifact is 1.521× faster than the
original row, but still assumes immutable private cell helpers; it is not a
fully mutation-safe production compiler result.

Guarding the recursive prefix consumes a substantial part of the avoided
descriptor/transfer cost. The result supports a small opportunity, not a
transformative speedup. A broader terminal-record region with proven scalar
purity can amortize its closure guard; this opaque state loop cannot reuse that
proof because its generic cell may invoke or mutate host state.

Short-window drift is extreme: second halves of ordinary-cell variants are
160–325% slower and private-cell variants are 25–34% faster. Treat those screen
ratios as lifecycle observations. Long-window halves differ by at most 3.03%
except one private baseline sample at −5.53%; all remain reported. The screen
costs 13.192s end to end and confirmation 147.100s. These timings include identical
host fixture allocation and complete state serialization; the TypeScript ratio
does not describe full edit distance or a production-program average.
