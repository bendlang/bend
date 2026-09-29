# Exact cached-prefix syntax identity

Independent review of the live-instance boundary found two omissions in the
existing exact prefix guard. This is a separately validated correction from
installed Phase17, without any live-checker or contextual-parser changes.

KLiteral stores kind, number and text outside the generic projections compared
by exact_term. Distinct numeric/text payloads can therefore compare equal.
KLambda also records whether its quantity was explicitly written; that fact is
part of canonical template-key syntax and must not be erased by cache identity.
A semantic normalizer comparison is unsuitable because it intentionally ignores
some of these syntax distinctions.

The candidate first distinguishes compact literal representation and compares
its complete payload with existing core_literal_same. Other terms retain the
existing structural comparison plus k_quantity_present equality. An equivalent
expanded constructor remains different syntax. Source spans keep their historical
separate provenance contract; this correction adds no semantic representation,
cache format or public ABI.

Frozen source: selfhost/build/phase19/prefix-source-01/project, copied from
phase17/find-worker-source-01/project. Only src/check/prefix.bend changes, adding
two physical lines. The shared Phase19 live-checker candidate carries the same
correction, but its results are independent.

Validation: genuine checked B1 plus maintained36; direct parent-failure and
candidate controls for numeric/text payload, explicit quantity presence, old
KTerm lambda compatibility, unchanged syntax, nested terms and expanded spelling;
full2996 frontend no-regression gate because this guard affects cached checks.
If these pass, measure the same assembled candidate source under unchanged
TS/B/C/C/B/TS workflow, fresh CPU0 processes, 4MiB stack/4GiB heap and separately
validated Bend Base caches. The pin and all35host files must match. A process
regression above5% requires investigation before promotion; small differences
are screening noise, not a speed claim. Keep expected trust refusal separate
from successful type validation.

Promotion requires exact live-source/host membership checks, the named gates,
release verification and installed/relocated CLI checks. The current installed
compiler remains Phase17 until those checks close. No broad-language full
conformance or new self-reproduction proof is implied.
