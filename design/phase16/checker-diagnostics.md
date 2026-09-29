# Phase16 checker diagnostics: preserve original failures

Prospective bounded plan, frozen before candidate execution. Parent design is
[full_conformance.md](full_conformance.md). Upstream stays b2111cf; baseline is
Phase15 combined-02, API b8d658c564226a52764a435df86059aa3cea6b0c428bbde5341a62c2253c2e2d.

## Census and ownership

The Phase15 exact vector has 215 checker-phase-only differences. This owner
investigates 46 content observations:22 legacy,7 same-expectation/detail,17 other.
The span owner investigates169 source-related observations. Nine of those also
lack the shared unrestricted-binder note; this owner fixes note content and the
span owner fixes actual provenance. The parser owner handles all244 observations
whose phase is parse, including26 computed-match errors. Shape categories are
descriptions, never oracle normalization. The census JSON freezes every ID.

## First correction: retain structured results

The existing constructor checker already creates KChecked/DTrace failures, but
check_ctor_domain projects ce(r), and check_definition_type wraps the String in
bad. Convert the existing ADT/foreign validation chain to KChecked. Successful
checks retain the same order and do not render diagnostics. Preserve the actual
constructor KEnv name, telescope context and original failing term. Two kind-tip
failures need the actual terminal telescope term and bound context. Fourteen
ADT and one foreign observation are candidates; exact spans depend on the span
owner's generic origin changes. No second checker or replay is introduced.

Template_arg_done replaces every original failure by a generic message. Return
the original result. At infer_template, translate only a traced unbound variable
that belongs to the actual caller context, exactly as pinned def_inst catches
that one error; wrong types and genuinely unbound names retain their own errors.
Eleven observations exercise this branch. Keep specialization String failures
visible until their separate state/result boundary is designed.

Use the existing DDiagnostic.note through an optional sixth DTrace child, an
error-only internal representation. Preserve it when appending trail terms.
Replace the redundant typeless pretty-printer helper with upstream's fixed
non-inferrable term observation. The datatype-constructor suggestion belongs
in note. A shared kind-check wrapper attaches the unrestricted-binder note only
to the immediate expected-kind mismatch, preserving nested error precedence.

## Subsequent bounded corrections

After the first candidate's exact results, inspect template instantiation error
transport/order (seven legacy cases), synthetic generic names and duplicate
binder rejection, TODO accounting, bare family syntax, rewrite context, imported
display aliases and free-variable display. Each is a new frozen addendum and
fresh source/build attempt. Do not change successful semantics merely to align
an error message; adversarial positive/negative controls precede integration.

## Gates and limits

Use a genuine checked B1 equality-profile workflow, CPU2 only after parent
releases timing. Keep every failed build/probe. Freeze all46 content IDs plus
nine note IDs as check-lane strict upstream selection and the maintained36
focused cases. Inspect exact full diagnostic strings and all primitive result
axes. Additional direct controls distinguish an outer Kind error from a nested
type error, successful Many binders, constructor ordering, well-typed templates,
closed wrong-type templates, captured caller variables and genuinely unbound
variables. No fixture-name logic, expected-text tables, TypeScript fallback or
strict-oracle changes. Full2996-observation integration and controlled timing
belong to root. Local correctness process durations are not speed measurements.

Owned production files for first candidate:check/kernel.bend and
diagnostic/trace.bend. Source copies only under selfhost/build/phase16/checker-*;
curated source/tools copy excludes unrelated Phase6 artifacts. No live source,
old evidence, pinned TypeScript or host changes. Count source lines/definitions
and report preserved/nonexact diagnostics, not only exact gains.

Outcomes:[implementation report](../../implementation/phase16/checker-diagnostics.md).
