# S4: reduce declaration and frontend bookkeeping

Status: bounded design before implementation. Baseline: S3 commit `8cc51c1`,
15,687 Bend lines / 13,093 nonblank / 486,768 bytes. The 50% milestone remains
**8,254 lines**; another **7,433 lines** must disappear to reach it.

## Evidence and limits

The new static inventories are [declarations](../../implementation/phase7/s4-evidence/declarations-counts.json)
and [frontend/book plumbing](../../implementation/phase7/s4-evidence/frontend-book-inventory.json).
These are prospective costs, not implemented savings. The master design's stopping
rules still apply: retain functionality, count replacements and required host
logic, and do not obtain the target from formatting or moving work out of Bend.

Every compiler function is unsafe; 1,222 definitions have a separate preceding
law and 228 are already self-typed. All paired laws have simple matching binders.
The existing assembler emits types, laws, then definitions in their existing
module/source order. Conservative reference analysis identifies **425 laws** that
no earlier definition requires. Removing those law/fill pairs can retire 425
declaration events without reordering definitions or adding assembler behavior.

Use one binder per line, keeping `@unsafe` on its own line. This avoids obtaining
the saving from packing a signature. The prospective source reduction is 834
physical lines, of which 407 are deleted declaration separators, **427 nonblank
lines**, and 12,219 bytes. Excluding those separator newlines gives 11,812 bytes.
Source text and review-context bytes must be reported independently of event
counts. The tighter theoretical whole-signature ceiling is only 2,366 physical
lines even before real visibility/recursion constraints. It cannot fund 50%.

Other concrete pools are smaller: duplicate canonical loader traversals (about
61 net lines), duplicate error search (44), redundant selectors (52), three
duplicate list/name operations (39), and the unused `check_events` projection (9).
Direct-block, sole-caller helper inlining has a bounded additional opportunity;
gross helper size is not deletion credit because bodies and temporary bindings
remain. Nested/branch helpers receive no assumed saving. Pools overlap and must
be recomputed after each accepted change.

These proposals are **not a supported route to 8,254 lines**. S4 may publish
validated reductions while remaining open; neither these increments nor a failed
milestone investigation may be labeled the completed 50% phase. S5 still depends
on satisfying the actual milestone. Reassess the remaining architecture after
the bounded units instead of launching an unbudgeted wholesale rewrite.

## A. One definition for functions that need no forward law

1. Freeze the inventory and module hashes. Build an isolated source candidate;
   keep the installed S3 release intact while its checking is incomplete.
2. Convert only the named 425 fixed-order pairs to existing typed-definition
   syntax. Keep exact parameter order, names, quantities, types, return types,
   body bytes and unsafe markers. Preserve definition and manifest ordering.
   Retain all genuine forward laws; do not add a topological sorter, inferred
   signatures, generated hidden declarations or runtime adapters.
3. Begin with a minimal module slice to falsify syntax, quantity/unsafe and
   visibility assumptions. Compare normalized type signatures and selected emitted
   code. The dependency scan may conservatively retain laws; it must not miss a
   required one. Compiler checking, not the scanner, decides whether the candidate
   is valid. Record any failed candidate before adjusting its selection.
4. Require at least 400 fewer nonblank production lines and 11,000 bytes for the
   full unit, no runtime/host logic added and fewer declaration events. If no such
   reduction survives checking, reject the unit. Record physical separators
   separately; do not fold them into a conceptual saving.

Cheapest falsifiers: erased/dependent parameters, a self-recursive typed function,
cross-module forward references, mutually recursive helpers, and a law whose
unsafe fill used to affect signature visibility. The current language already
supports a mixture of typed definitions and forward laws; introduce no new
implicit generation rule. The one-off migration tool is an audited source edit,
not a required compiler build step, and its own code is counted separately.

## B. Share existing loader/error operations

Only after A is accepted or rejected, recost these units against its resulting
source. Freeze each exact change before implementation.

- Unify canonical seeded and unseeded graph traversal using the existing seed
  worker. Preserve missing-source handling before seed matching; an empty disabled
  seed must never turn an absent source into successful empty input. Keep public
  wrappers, trace ordering, source ownership, namespace/cycle errors and real Base
  invalidation. Do not fold the older public `f_load` into a different contract.
- Project legacy error queries from the existing structured frontend error walk.
  Preserve first-error order, exact strings, token metadata and empty/error cases.
  Retain aliases still used by historical probes; no new error representation.
- Replace truly duplicate selectors/list/name operations with their existing
  equivalents and retire the newly unrooted checker projection. Verify quantities,
  ordering, malformed public inputs and actual external roots for each unit.
- Try directly tail-called private continuation helpers only where a local
  binding/destructure can preserve argument evaluation, sharing, tail behavior
  and scope without introducing a new combinator or giant nested expression.
  Keep recursive and branch/nested candidates out until separately justified.

## Gates and reporting

Use fresh checked attempts and the 21 focused controls for each meaningful source
change. Freeze current S3 APIs/host as the behavioral reference and pinned upstream
as the language reference. Run relevant components and boundary controls.

For A, exact selected API/runtime/host identity permits reuse of S3's full frontend
and runtime evidence with that explicit scope. It does not prove the new source
can reproduce itself. Verify multiline typed definitions through the Bend frontend
and perform genuine checked self-reproduction before calling the source-authoring
migration a usable self-hosted integration. Any changed selected artifact broadens
the full frontend, diagnostic and performance gates rather than weakening them.

For B, run affected raw/parsed/seeded loader and provenance controls, full frontend
preservation for the integrated candidate, and serial accepted/rejected cost
comparisons. Preserve the 5% runtime/iteration and 10% memory/size guards. A stable
artifact can receive a single broad integration gate after its focused units;
do not rerun long jobs for unrelated documentation changes.

The milestone still requires checked B1→H→H equality, supported backend execution,
relocated release integrity, full frontend coverage, fixed review-context counts
and controlled performance. Restore/verify Clang before claiming native execution;
GPU hardware absence remains explicit. Keep previous valid artifacts until each
replacement passes its own gates. Do not promote a source increase as simplification.

Write an evolving `implementation/phase7/s4-report.md` with unit outcomes, exact
costs, retired contracts, failures and current milestone shortfall. Preserve
immutable experiment inputs and raw evidence. Commit/push validated increments;
mark the phase complete only if the 50% ceiling and full milestone gates actually
pass. If the evidence exhausts safe candidates, report that boundary and retain
the last usable smaller compiler rather than manufacture a percentage.
