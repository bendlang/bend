# Phase18: inexpensive state transport for the remaining semantic work

Both representation experiments pass their scoped correctness gates, and both
measured prototypes stay within the prospective 5% process-overhead screen.
They remain isolated: the usable compiler is still the Phase17 lookup-worker
release. This phase fixes no conformance gap and removes no compiler concept.
Its result is evidence that the next semantic changes need not begin with a
large transport cost.

| Experiment | Result | Compiler source cost |
| --- | --- | --- |
| Checker world, measured source03 | Essentially flat process time; request +0.39%, peak RSS +0.42% | +87 physical lines, +13 definitions, +2 types |
| Checker world with stable public boundary, source06 | Maintained36, chronology22, direct42, memo8 and public18 pass their scoped contracts; not separately timed | +107 physical lines, +16 definitions, +3 types |
| Inert parser cursor, source02 | Process +0.93%, request +1.06%, peak RSS +0.74%; 196 unchanged outcomes and 194 direct controls | +77 physical lines, +13 definitions, +2 types |

Each starts independently from the same Phase17 source. Do not add the measured
percentages or call these changes a combined compiler. The source costs use the
same 59 ordered-module denominator as the installed 16,353-line compiler.

## Checker result

The [world experiment](instance-world-correctness.md) shares an immutable source
book, instance memo and explicit fresh-state availability through checker
environments/results. Ordinary entry defers fresh-bound computation, preserving
previously undemanded books and bodies. Error translation retains the originating
world, and generic success/failure scopes have separate controls. No instance
minting, child-effect sequencing or duplicate-visitor removal happens yet.

The [controlled source03 measurement](instance-world-cost.md) is 11.7103→11.6839 s
on identical source, versus pinned TS3.4098 s. Two samples per lane support a
neutral screen, not a speedup. Review then found that a low-level public
KSpecialized result exposed the larger internal record. The
[source06 boundary](instance-world-public-boundary.md) restores the historical
four-field public KChecked and uses KChecking internally, sharing a
small payload renderer. The raw public value/shape and first demanded failure
are tested; repeated reads of arbitrary stateful JS getters are not an invariant.
Source03 timing is not a measurement of that later adapter.

The two saved instance chronology gaps still fail exactly as before. Their fix
requires the existing checker to check a newly minted instance immediately,
return its state, and resume the caller in order. Returned worlds must also reach
normalization/comparison and diagnostics. Successful private scopes must retain
new global instances; source definitions must retain their source bodies.

## Parser result

The [cursor experiment](cursor-representation.md) changes cursor transport while
keeping grammar and scoping unchanged. Complete raw/lowered Base and compiler
books agree, as do all196 saved results. The raw suite still has68 strict
differences; preserving them is the inert-stage contract, not conformance.

The [uninstrumented measurement](cursor-cost.md) is11.6339→11.7416 s, versus
TS3.4239 s. A separate probe counts11.62 executed cursor-construction expressions
per compiler token. That count is not physical V8 heap allocation; the measured
whole-host cost is small enough to investigate semantic ownership first.

The [independent review](../../design/phase18/parser-semantic-slice-review.md)
traces the main monad failure to parsing the continuation before validating the
completed left pattern. A narrow stopped-body solution still needs substantial
scope, callback and partial-prefix machinery. The next experiment instead puts
names, binders and pattern checkpoints in the existing parser control flow.
Unbound ordinary names must retain their global fallback until their grammatical
role is known. Public raw parser results and FCompletion.parsed need an explicit
stage boundary; silently returning scoped books would be a compatibility bug.

## Decision, limitations and records

Proceed with private, separately checked Phase19 semantic slices. Their first
gates are the saved chronology witnesses and full scoped result comparisons.
Their later integration gates include broad frontend/backend results, public
loader/prefix histories and a new controlled cost comparison. A transport
screen does not establish the cost or correctness of lexical stacks, real
instance effects, memo-only materialization or a combined compiler.

All failed preparations/builds, the public-demand counterexample and corrected
attempts remain. The Phase18 preservation plan captures these closed experiments
separately from active Phase19 work; its completion is recorded in a separate
receipt. Phase17 release evidence is independently recovered and committed as
`b34f8cd`. The installed API remains `9b20de50`, with two main frontend diagnostic
differences and separately documented broader gaps. No new release, full
conformance, generated-code speedup or remote publication is claimed here.
