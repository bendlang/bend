# Grouped body boundaries: prospective experiment

Status: **unexecuted**. This document records source inspection and proposed
controls only. No Phase21 compiler source, build, oracle run or performance
measurement has been produced. Phase20 integration must close first; the root
will select its immutable production parent and authorize the next probes.
Pinned reference: `b2111cf`, locally preserved in
`selfhost/.bootstrap/upstream-phase8/bend2/bend.ts`.

The immediate recommendation is a small, independent source-range experiment
targeting three observations. The other two observations expose a grouping-stage
distinction that the production raw parser has erased. A comma guard alone is
not a safe five-observation fix. Do not import the unfinished contextual parser
or add duplicate pattern validation to make these five examples pass.

## Recorded frontier and exact targets

Use the unchanged selection at
`selfhost/build/phase18/cursor-controls-01/selection.json` and original fixtures
under `selfhost/build/phase17/group-controls-03/fixtures/`. Recorded paired
outcomes are in
`selfhost/build/phase19/context-row-validation-01/selected/paired.json`.
That collection has196 observations,136 exact and60 differences. Its raw suite
verdict remains false; the independent Stage4 audit establishes eight gains and
no lost exact matches, not full-suite success. Phase20's production rerun is the
required next baseline, so these counts are not a claim about an unbuilt parent.

| Saved ID | Lane(s) | Pinned outcome | Recorded self-hosted difference |
| --- | --- | --- | --- |
| `group/body-comma` | parse, check | Parse rejection: expected `')'`, observed `','`, caret at comma | Wrongly accepted, including a checked acceptance |
| `group/local-pattern` | parse, check | Pattern rejection, observed `x = {0n : Nat}; x`, caret at the inner binder `x` | Same diagnostic and phase, but caret covers the whole parenthesized body |
| `group/local-callee` | check | Cannot infer `identity`, caret at local binder `f` | Same diagnostic and phase, but caret covers the whole parenthesized body |

The separate `group/local-callee-parse` observation already agrees and must stay
accepted. No monad or same-body instance improvement is claimed by this plan.

The three source snippets are:

```bend
# group/body-comma
import Base
def main() -> Nat & Nat:
  (x = {0n : Nat}; x, 1n)

# group/local-pattern
import Base
def main() -> Nat:
  (x = {0n : Nat}; x) = 0n
  0n

# group/local-callee
import Base
def identity(x: Nat) -> Nat:
  x
def main() -> Nat:
  (f = identity; f)(0n)
```

These excerpts identify the cases; gates consume the existing exact fixture
bytes, including their original spacing, rather than reconstructed excerpts.

## Shared source owners and the reference boundary

Pinned `parse_term_tup` first calls `parse_body`. A comma makes a tuple only when
the returned body is neither `Local` nor `Match`. For a body, it calls the one
`body_flatten` owner before parsing an optional namespace annotation and before
requiring `)`. A completed inner group is already an LTerm: a plain local is a
`Let`, so that term can legally be a tuple component in an outer group.

Pinned `body_flatten` gives a plain local's resulting `Let` the source range of
its first binder (`ws[0].s`). Parallel and typed locals share this rule. A single
constructor pattern is different: it delegates to `match_flatten`, whose origin
comes from the RHS. It is not generally correct to assign every lowered local
the first written pattern's range.

Production `front/declarations.bend:f_let_body` constructs a raw `Local` without
a range. When that local is parenthesized, `front/parser.bend:f_locate` and
`f_span_created` fill the absent range from the entire group. The existing
`f_scope_local_valid`, `f_flat_let` and `ff_let` then preserve that range. The
pattern-error producer in `f_valid_pattern` uses the raw pattern's origin while
showing its scoped value; changing only `f_flat_let` would therefore miss both
`group/local-pattern` observations.

Production `f_group` accepts a comma unconditionally. Its successful non-tuple
branch also returns the raw body unchanged. The later `f_scope` owner lowers
grouped Local/Match through `f_flat(f_scope_body(...), Nil{})`; grouped Parallel
has the corresponding shared worker. These are the older `f_flat_*` workers,
not necessarily the stateful `ff_*` path recently tested in the private parser.
Moving only the private flattener's Var/error guards cannot restore an erased
group-completion boundary or these ranges.

## R1: first-binder origin, isolated from comma syntax

Hypothesis: locating a successfully constructed ordinary raw `Local` at its
actual first binder removes the three recorded caret differences without a new
semantic pass, source scan, result type, host route or checker change.

The smallest source candidate is the existing `f_let_body` construction in
`front/declarations.bend`: preserve its current child-error choice and use
`kt_span` with the existing pattern's `kb`/`ke` instead of the unlocated `kt`.
This reuses the existing later origin transfers and `f_locate`'s rule that an
already located parsed subtree keeps its own range. It adds no definition or
datatype and need not add a physical line. The anticipated effect is three new
exact observations, no acceptance or phase changes, and no measurable speed
claim. Actual bytes and definitions must be counted from the frozen candidate.

This one-expression candidate is a hypothesis, not a universal assertion about
every raw Local. Before source preparation, freeze pinned controls for ordinary,
typed, erased, marked, empty-call and constructor-destructuring locals. A
constructor-destructuring group's lowered span must remain the RHS span; a
computed-pattern error must use its actual resulting term's reference span.
Include the case where that whole group is itself an invalid pattern. If the
unconditional producer change loses an existing exact result, retain it as a
failed attempt and review a bounded owner correction. Do not invent a new
name-validity classifier in `f_let_body`, infer syntax from offsets, or silently
broaden R1 into a general diagnostic renderer change.

`front/parallel.bend:f_parallel_body` is the analogous producer and should be
tested as a neighbor. Its correction, if needed, is a separate prospective delta;
none of the three saved targets requires it. Synthetic write binders may have
absent origins. Legacy unindexed input must retain0/0 rather than fabricating a
location. No full-tree range normalization is authorized.

Independent R1 controls must retain complete raw and lowered terms/ranges, not
just normalized error strings:

- Single and multicharacter binder names, nested groups, same-spelling nested
  binders, comments/newlines and a preceding astral character. Compare actual
  UTF16 endpoints, not character counts or a source search for the name.
- Grouped locals as a callee, argument, annotation value/type, namespace-annotated
  term and outer pattern; ordinary ungrouped locals as unchanged neighbors.
- Typed, erased and marked binders; valid bound empty calls versus unbound
  empty calls; single constructor and literal destructuring, including nested
  constructor fields and destructuring groups used as outer patterns.
- Parallel first/second binder origins and a constructor pattern in the
  names-only parallel/typed position. Existing pattern eligibility and error
  priority must remain unchanged.
- Earlier RHS syntax failure, invalid inner pattern, later continuation failure
  and missing `)`. R1 changes origin ownership only and must not reorder them.

The existing saved `group/local`, `group/nested-local`, `group/local-argument`,
`group/local-callee-parse`, `group/local-namespace`,
`group/nested-local-namespace`, `group/local-annotated`, `group/local-type`,
`group/parallel`, `group/nested-parallel`, `group/local-lambda-body`,
`group/local-lambda-binder`, `group/local-marked`, `group/local-bang`,
`group/missing-close` and `group/rhs-error-before-close` remain visible too.

## C1: comma eligibility needs a preserved completion boundary

Two decisive source-derived counterexamples prevent immediate promotion of a
raw-tag comma guard. They have **not been executed in Phase21**; freeze exact
oracle fixtures and both-lane baseline outcomes before choosing any source edit.

1. `(x = {0n : Nat}; x, 1n)` must reject at the comma. But
   `((x = {0n : Nat}; x), 1n)` is expected to be a valid tuple: its first element
   is the completed inner `Let`. The current raw producer still returns `Local`
   after that inner group. A blanket tag exclusion confuses these two stages.
   Include parallel and Match counterparts and ordinary `(0n, 1n)`/nested tuples.
2. `(Type = 0n; 0n, 1n)` is expected to reject the invalid pattern before a
   comma diagnostic. In the pin, local pattern validation happens before the
   recursive continuation, and grouped flattening happens before requiring `)`.
   An immediate comma error discards the body that owns that earlier refusal.
   Include invalid constructor arity, earlier RHS syntax and a grouped global
   match before the comma/close to distinguish all three checkpoints.

The expected first-error sequence is RHS syntax, local pattern validation,
continuation parsing, group flattening, namespace annotation, then required `)`.
For Match, row arity/pattern validation precedes its row body, while flattening
is deferred until the enclosing group. Ungrouped rows retain that deferral.
Later row syntax can therefore win over an ungrouped flatten error; a completed
inner group's flatten error can win before a later sibling is parsed. Keep the
original saved16 stage observations as the independent order oracle.

The Phase17 `FGroup` ablation already tested a small explicit completion marker:
eight added lines, one helper, existing `f_scope_body`/`f_flat` reuse, no new core
datatype or host ABI. It deliberately retained the old comma branch and gained
zero observations. A success-only marker can distinguish the nested positive
tuple, but does not preserve a body discarded on a later comma/closing error.
Its report and failures remain at `implementation/phase17/group-boundary.md`.
Do not present that old result as an implemented solution to C1.

The completed private Phase19 row/group slice demonstrates the actual semantic
boundary using the shared grammar and flattener, but its partial syntax result
is not production Core/loader conformance. Installing it only to obtain two
observations would import substantial unfinished scope. A new rejection wrapper
would also need an explicit lexical-context, first-error and outer-frame
propagation contract; it is not merely a one-line grammar correction.

Recommendation for C1: run the decisive existing-baseline/pinned neighbors after
authorization, retain their raw trees and precise failure stages, then stop for
review. Do not implement a second pattern checker, scope a body with an empty
environment, flatten successfully parsed prefixes twice, or infer completed
grouping from ranges/IDs. No bounded production solution for the two comma
observations is established yet. R1 can proceed independently.

## Gates, identities and stopping rules

After Phase20 closes, freeze the exact selected production source/checked API,
complete parent membership, upstream/tool/runtime/Base identities and unchanged
saved196 selection. New preparations, snapshots and reports use only Phase21
`group-*` paths; prior evidence is immutable. Freeze controls and actual oracle
results before candidate source. Preserve mistaken fixture/preparer attempts
with their original IDs and outputs.

Build R1 as genuine checked B1 on authorized CPU3, followed by maintained36,
the five targets and independent neighbors. Compare the complete saved196
vectors against the exact production parent; all prior exact matches must stay
exact and only independently established pinned improvements are allowed.
Separate raw-suite failure from a healthy collection/no-regression audit.
Check exit status, signals, timeouts, missing rows and errors inside child reports.

Direct controls compare complete Base/compiler raw and lowered books. An
origin-only patch intentionally changes some origin fields; retain both complete
graphs and enumerate each changed node with its producer/path/range. Do not
erase all source metadata to manufacture equality. Names, IDs, quantities,
children, accepted programs, materialized output and error order remain strict.
After cheap gates pass, root decides the full frontend/backend gate and any
exclusive cost screen. No concurrent compiler/probe/hash work during a root
timing hold, no speed claim from constructor-count reasoning, and no installation
until independently reviewed.

R1 stops if a correct origin requires duplicating name/pattern semantics or
another traversal. C1 stops after its decisive controls unless root separately
approves an explicit completion/failure transport design. The current estimate
is **three plausible cheap exact gains; two semantic gains not yet justified by
a safe small patch**, rather than an unconditional five-row promise.
