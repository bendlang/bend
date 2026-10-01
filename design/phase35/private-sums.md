# Next experiment: saturated private traversal of existing tagged sums

This design began as a prospective saved-output experiment. Its initial
greater-than-twofold target was a discriminator, not a prediction; measured
prototype evidence and the subsequent compiler subset are recorded below.
The Phase34 profiles and exact pinned modules show substantial
generic call/matcher work in symbolic regression, bitonic sort and the lexer.
The TypeScript versions already use ordinary saturated functions, tag tests and
field reads; neither a new tree layout nor more sophisticated arithmetic is
needed to test that difference.

## Actual rejected predicates

Inspection used the exact baseline and TypeScript modules identified in
[Phase34 opportunities](../../implementation/phase34/opportunities.md).

| Path | First relevant refusal | Additional independent restriction |
|---|---|---|
| Bitonic `bsort` | `j_nat_scalar_shape` reaches `j_nat_loop_signature`, whose result test rejects recursive, two-constructor `Tree` | `j_tree_right` gives the combination only the two child results, but `bsort` also needs captured parent `p` and `s` |
| Symreg `cand` → `gen` | `j_region_capture_eligible` checks the helper signature; `j_region_local_one` cannot admit six-constructor `Expr` | Type recursion, complete sum matching and the active-helper cycle check independently reject recursive `eval`, `esize` and `gen` |
| Lexer `batch` → `line` → `lex` | The scalar fork shape is potentially acceptable, but helper signature admission rejects native `String` | `Mode` is a three-constructor sum; SCon/Chr and tail recursion need a native-string-specific rule |
| Symreg `batch` itself | A flat `Sel` result can pass the Nat result test, but the next `j_region_signature` insists on a scalar result | Its `cand` dependency still reaches recursive `Expr` |

These are static control-flow traces through the admission code, not instrumented
rejection logs. Removing only the first predicate would be unsound and would not
make the programs eligible. In particular, reusing the current scalar tree stack
does not resolve sum representation, closure planning or parent captures.

## One architectural extension worth testing

Allow a bounded graph of saturated private helpers to consume and produce closed
tagged sums, retaining the existing `{$: tag, a: fields}` representation. Match
dispatch becomes a complete tag decision with direct fields, and proved recursive
calls refer to private helper declarations. This is a change to private graph
admission and calls, rather than a new universal optimizer or public record ABI.

Start with self recursion and an otherwise acyclic helper graph. Reserve a typed
helper entry before analyzing its body; a recursive reference may use that entry
only at the exact arity and with the checked argument/result types. Finish and
publish the region only if every reserved body validates. Preserve the existing
node/helper/depth budgets. A completed-cache hit is not a sufficient recursion
proof, and simply deleting the active-cycle check is unacceptable.

For the first production subset, recursive calls must consume a direct recursive
constructor field or the already proved Nat predecessor. A closed local producer
establishes inert, finite data; arbitrary public objects retain the generic
path. Existing tail loops stay loops. Non-tail direct recursion needs either a
proved small local depth or an explicit continuation stack before general
promotion. General mutually recursive SCCs and public tree validators are later
work, not prerequisites for this first test.

The same mechanism could later cover bitonic trees and finite lexer modes, but
native String/Char matching remains a separate adapter. No single small patch
can honestly claim to cover all three today.

## Smallest saved-output discriminator: symreg candidate

`cand(s, pts)` already has one complete two-scalar public callback. Its tree is
created internally by `gen(5n, prng(s))`, cannot escape, and is reused across the
dataset. That fixes recursive tree depth at five while preserving sharing and
the existing tagged records. It is a cleaner first boundary than accepting an
arbitrary caller-supplied tree in public `eval`.

The producer prepares three modules from the exact frozen symreg output:

1. `baseline`: original algorithm definitions;
2. `loop`: guarded complete `cand` entry, original generic `gen`, private Nat
   dataset loop, original generic `eval`, `esize` and `adiff` calls;
3. `sums`: the same loop, but private saturated `eval` and `esize` over the
   original tagged tree. `adiff` remains generic to keep the comparison narrow.

The second-to-third comparison isolates recursive ADT dispatch from the Nat loop
change. Original `bench` and every other exported function remain available;
the complete documented-small benchmark therefore transfers without changing its
workload. A separate candidate point sums the three Sel fields across several
seeds and dataset lengths. It is a mechanism screen, not the representative
corpus.

The new exact callback reads the original two array slots once and keeps the
original fallback source. Before scalar input checks or generic generation, it
checks captured host identities/protocol descriptors and every transitive G
dependency. A changed generator must fall back, including generators returning
getter-backed or aliased trees. Generic generation uses `force` and construction
arrays, so the prototype additionally snapshots Array push/pop and prototype
properties rather than relying only on the prior scalar marker guard.

This guard is deliberately conservative and **uncertified** until independently
reviewed and executed. Stable standard host intrinsics at module initialization
remain an explicit scope. A saved-output rewrite is never promoted as the Bend
compiler implementation.

## Controls before timing

An independent tree generator/evaluator must validate every constructor, wrapped
arithmetic, repeated subtree sharing, several seeds and dataset counts including
zero. Check all three Sel fields, not merely the final tournament checksum.
Compare the original full benchmark as well. Add an admission witness separately
from clean timing.

Public tests must cover every partial prefix, zero/exact/oversaturated/raw calls,
callback own properties, constructor behavior, argument getters and reentry.
Replace or accessor-wrap each captured G dependency, mutate after saving a
prefix, and supply an overridden generator returning field getters, aliases and
errors. Verify ordered effects and errors against the untouched path. Post-import
Math/Number/BigInt and Array iterator/species/push/pop hooks must force fallback
without extra hook calls. Instrumented diagnostics are never timing samples.

Only after these pass, measure a small candidate sweep and then the unchanged
symreg benchmark. If the twofold screen fails, keep the result: it distinguishes
guard placement, remaining generic generation, and ADT traversal rather than
justifying a larger framework on intuition.

## Measured discriminator and production subset

Root's corrected prototype passed 71 independent oracle points, 121 paired
public boundaries, and a separate admission witness. The original complete
symreg workload took 109.263 ms; the private loop alone took 110.485 ms, and the
loop plus direct sum consumers took 20.223 ms in the same rotating screen.
The pinned TypeScript output took 1.111 ms. These are saved-output mechanism
results, not a promoted compiler claim. The initial all-fallback guard failure
and its repair remain in the [report](../../implementation/phase35/sum-review.md).

The production proposal preserves the tagged representation and generic
producer. A separately proved pure generic call completely materializes the tree
before a private consumer receives it. This shares `j_pure_type` and
`j_pure_graph` with partial regions; it does not add a second call-graph proof.
Public entry parameters remain native scalars. Public functions accepting trees
and any replacement producer continue through their original callbacks.

`src/back/js/fold.bend`, immediately after `region.bend`, recognizes one narrow
structural family:

- A closed monomorphic nonnative Data sum has 2–8 constructors. Every constructor
  has at most two fields, each canonical U32 or the same recursive sum.
- A consumer takes the sum first and at most seven unchanged U32 parameters,
  returning U32. Its complete constructor permutation ends in Efq, with exact,
  distinct field/parameter binders and no lifted function prefix.
- Each recursive field appears exactly once as the direct first argument of a
  fully saturated selfcall. Remaining arguments are unchanged scalar parameters.
  The surrounding expression contains only strict native scalar primitives,
  literals and nonrecursive fields/parameters. Conditional calls, Let bodies,
  duplicate/missing children, higher-order calls and other recursion are refused.
- The planner replaces those child calls with scalar-result slots, then runs
  the existing typed region expression planner again. This catches incorrect
  operand types rather than treating a native primitive name as sufficient proof.

Emission uses an explicit postorder frame stack, with a reusable frame per active
depth. Children are visited in source operand order, including right-before-left
expressions. The first result survives the second traversal; shared subtrees are
traversed each time the source demands them and never mutated. This avoids a
native-recursion depth limit without assuming that every producer uses depth five.
Bounds remain explicit: 8 consumer arguments, 8 constructors, 2 fields, 128 levels
of strict scalar expression analysis, existing 8,192 source-node and 32 helper
caps. This is not a general SCC optimizer, arbitrary tree rewrite or fold fusion.

Every enclosing region containing a fold requires the shared host guard even
without a residual producer. It protects the movement of numeric primitive work
relative to child traversal. The frame emitter must not read an absent array
slot. Post-import inherited numeric Array/Object prototype hooks must force the
original path before any generic producer or private consumer can invoke them;
otherwise they could mutate a captured G helper after the one-time guard.

Ordinary scalar-input roots may return an existing flat scalar record. The
relaxed primitive-expression field rule applies only to a root's terminal
constructor, using an internal context marker; the original tail `build` and
its field thunks remain. Private eager constructors retain their former stricter
rule. Any such root uses the host guard. No helper calls or allocation graphs
are newly admitted inside delayed fields.

## Final checked-compiler gate

Run `python3 selfhost/tools/performance/phase35/fold-final-controls.py ATTEMPT NEW_OUT`.
It acquires the same checked fixture with the historical baseline, selected
candidate and pinned TypeScript compiler, then runs compiled oracles and separate
synthetic planner refusals. It owns one serial execution lock, CPU3, 1 GiB Node
heap, 2 GiB process-tree ceiling and 2 GiB available-memory floor. The final
receipt hashes the selected API, all producers, checked emissions and reports.

The fixture includes unary depth 50,000 generated locally, shared subtrees,
right-first noncommutative combination, unchanged extra arguments, wrapped
arithmetic, retained delayed record fields, and duplicate/changing-argument
refusals. Small points compare all three compilers to independent BigInt
arithmetic; the deep-stack requirement applies to the new candidate. Separate
diagnostic admission counters establish that optimized consumers actually ran.
Public prefix/raw/oversaturation/getter and helper/host/numeric-prototype mutations
compare candidate observations against the original callback path. Final actual
symreg transfer and broader maintained gates remain root's admission requirements;
the prototype's 5.4× gain cannot substitute for those results.
