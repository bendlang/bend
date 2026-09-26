# Remaining architecture: the 50% budget is still unfunded

Read-only assessment during S4-A validation. No compiler, host, tests or build
tools were changed or run by this reviewer. Counts below use the isolated
**425-pair draft**, not a promoted compiler: 14,853 lines / 12,666 nonblank /
474,549 bytes. That draft has since failed API identity because the existing host
detects the literal laws for `annotate_selected` and `j_layout_error`; removing
those two laws omits their exports. Root is retaining them in a 423-pair candidate.
Its final counts and validation supersede the illustrative draft counts here.

**There is no evidence-backed design for another roughly 6,000 lines of net
reduction while preserving the present functionality and performance budgets.**
This is a limit of the identified opportunities, not a proof that no better
compiler could exist. A smaller implementation remains useful progress; a
wholesale rewrite cannot be justified by an invented savings ledger.

## What the TypeScript comparison actually says

The pinned language implementation is 3,870 lines / 132,537 bytes; the first
3,278 compiler-oriented lines of `comp.ts` are 104,486 bytes, excluding its large
embedded runtimes. Together: **7,148 lines / 237,023 bytes**. This is the existing
Phase 7 comparison boundary, not a new exclusion chosen to favor the reference.

| 425-pair Bend draft | Lines | Bytes |
| --- | ---: | ---: |
| Core | 2,395 | 66,836 |
| Checking, specialization, annotation | 2,758 | 74,499 |
| Frontend | 3,832 | 119,934 |
| Loader | 1,119 | 33,116 |
| Diagnostics | 787 | 26,946 |
| JS backend | 1,738 | 55,390 |
| Native backend | 2,034 | 92,811 |
| Driver | 190 | 5,017 |

The first five subsystems total **10,891 lines / 321,331 bytes**. Keeping the
current backends and driver leaves only **4,292 lines** for those subsystems at
the 8,254-line milestone: they would have to shrink another **60.6%**. The raw
draft gap is 6,599 lines; retaining two laws makes it slightly larger. Small B
pools do not change this order of magnitude and must be recounted after A.

TypeScript expresses most of its compactness with mutable dictionaries/arrays,
exceptions, local control flow, closure-valued binders and mutable sharing cells.
`bend.ts` has 142 function declarations; the compiler-oriented `comp.ts` has
167. Bend's 1,450 definitions are not 1,450 language concepts: many are explicit
continuations, projections and state transports. Conversely, collapsing their
signatures does not remove their behavioral contracts. Both implementations still
need scopes, ordered declarations, dependent substitution/conversion, quantity and
termination checks, templates, pattern compilation, effects and target layouts.

Relevant pinned source: `bend.ts` 275–311 defines higher-order bodies and books;
661–878 implements apply/higher/lower conversion; 1539–2656 implements parsing;
2859–3270 implements evaluation/conversion; 3692–3755 checks and materializes
templates. The compact TypeScript `def_inst` mutates `book.tmps` and `book.tlds`
and writes the checked body to `inst.e`. The current reusable first-order Bend
core cannot adopt those operations as a textual port: it needs explicit ownership,
state propagation, cache validity and public ABI decisions.

## Whole-pass candidates, with honest ceilings

These disjoint pools use the draft's already-reduced modules. **Gross means every
line in the named modules, not deletable redundancy.** No replacement below has
been implemented or budgeted tightly enough to credit a net saving.

| Architectural proposal | Gross module pool | Replacement that must be paid for | Net currently credited |
| --- | ---: | --- | ---: |
| Checker produces specialized, typed executable terms | `check/specialize` 916 + `check/annotate` 386 = **1,302** | Closed-instance memo/recursion handling, transformed dependent types, erased arguments, valid facts and immutable updated-book threading through checker results; backend/public adapters | 0 |
| One evaluation machine for weak heads, strong forms and conversion | `core/normalize` 534 + `core/graph` 475 = **1,009** | The same reduction rules, opaque/under-applied definitions, shared cells, heap updates, deep work frames, strong readback and conversion; a cheap weak-head entry | 0 |
| Resolve scopes and allocate binders once in the frontend | `front/elaborate` 482 + `flatten` 270 + `families` 203 + `fresh_work` 200 + `freshen` 57 = **1,212** | Pattern matrices, ordered field names, quantity joins, imported/parallel scopes, capture avoidance, templates and stack-safe traversal; parser/loader changes are additional | 0 |
| Carry source occurrence metadata directly | `diagnostic/frontend` **229** | Source identity/ranges through every relevant parser/core transformation and compatible public origin queries; remaining location/rendering rules | 0 |
| Replace the custom book index with existing Base Map | `core/index` **339** | Ordered events/final selection and public cache contracts remain; typed storage, exact-name semantics and adapters; benchmark the different key algorithm | 0 |
| **Disjoint total** | **4,091** | Substantial required functionality remains in every row | **0** |

Even deleting all five pools with **zero replacement cost** would leave 10,762
lines, still 2,508 above the milestone. This is not a valid implementation plan;
it shows why these ideas do not finance the requested reduction. Adding all 3,772
backend lines to a gross ledger would merely count two required compilers as
deletable. Their combined size is only 494 lines above the pinned TypeScript
backend boundary, which also implements native optimizations the port lacks.
Reaching that backend line count would not close the remaining gap.

## What is promising, and what would break the argument

The most coherent larger research direction is a **single checked output
contract**: checking materializes template instances and retains the exact facts
needed by erasure, replacing the separate specialization/annotation boundary.
It could remove a real whole-book pass and improve semantic alignment with
upstream. The 1,302-line gross pool is worth investigating, but a claimed 600-line
net gain would require *all* replacement state/fact/instance logic and bridges to
fit within 702 lines. There is no evidence for that bound. The historical
[typing-fact counters](../../phase6/typed-facts.md) found no repeated exact inputs
for annotation type/spine reconstruction; a generic cache is not a substitute
for this design. A smallest research slice needs dependent and erased template
arguments, recursion/instance reuse, preserved first errors and an actual backend
consumer before it can establish any net budget.

Unifying evaluators is a smaller, riskier size opportunity. There is no spare
interpreter to delete: `driver_interpret` already calls `strong` and `kp_show`.
The same evaluation semantics are needed for dependent checking. The graph heap
preserves shared recursive demands; deleting it in favor of naive substitution
would lose the existing deep/shared tests and can cause exponential work. Making
every cheap weak-head query allocate graph state could instead regress checking.
Retaining one interface does not itself retire those invariants.

Likewise, a source cursor cannot simply delete the parser's remaining grammar,
scoping and pattern algorithms. Parser-owned scopes could retire repeated walks,
but error order, module namespaces and generated binder names must survive.
An explicit term sum can improve local understanding, yet generic child walks
would become per-variant cases; the small accessor pool is not a whole miniature
compiler that disappears. S0 already recorded representation/provenance candidates
that grew source and required bridges. Those counterexamples still apply.

Base actually provides `Map` (`base.bend` 81–84, operations 2335–2775), so map
reuse is legitimate Bend library reuse, not a host offload. But it uses string
bit positions represented by `Nat` and returns ownership-preserving map/result
pairs. The current index uses U32 hashes, exact collision buckets and `KDef`
cache markers. The whole 339-line index module cannot be credited as deletion,
and equivalent throughput cannot be assumed. The existing compressed index has
[measured performance history](../../phase1/rapid_performance_experiments.md).

## Decision

Finish and measure the bounded A/B units with their actual budgets. The missed
`law`-text export probes demonstrate why source authoring, host selection and
public roots all belong in the review context: internal call-graph reachability
alone is insufficient. Keep the supported compiler and the 50% milestone open.

Beyond B, a bounded checked-output redesign is meaningful research if it first
earns a net reduction and preserves the performance/semantic gates. It should
not be presented as a funded path to 8,254 lines. No signature packing, removed
backend, hidden compiler generator, runtime interpreter replacing efficient
emission, or moving an index into a new excluded helper library can supply the
missing budget. A credible 50% proposal must identify a substantially different
source of savings and price its replacements before production implementation.
