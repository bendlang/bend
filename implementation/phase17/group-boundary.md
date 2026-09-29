# Phase17 group-boundary ablation

The isolated marker passed its cheap correctness gates and remains a research
prerequisite. It is **not installed** and produced **zero conformance gains**.
It preserves a grouping boundary needed by a future failure-checkpoint resolver;
that resolver has not been implemented, and monad_do_destructure is unchanged.

The parent is the complete Phase16 compact-final-source-01/project, checked by
compact-final-build-01 (API35044ae6f6cd9bb63690536588c11761695c66cbf524db8bcd3baa6453ed5315).
The candidate is group-source-02/project, checked by group-checked-01
(API0b9f57d26cb0660531e0f7335fb292e13c9fefe86f491e48554a11e5f8312a3e).
Both use pinned upstream b2111cf. The [prospective plan](../../design/phase17/group-boundary.md)
and each source attempt's consumed-plan.md preserve the original plan and the
approved source02 addendum. The source01 plan predates that appended addendum;
its preserved bytes match its recorded plan hash.

The parser's successful non-tuple group completion wraps only raw Local, Match,
or Parallel bodies in a unary FGroup. Scalar groups, tuples, errors and already
marked groups retain their forms. The existing scope worker consumes FGroup
through f_flat(f_scope_body(child, env, book), Nil{}). This preserves lexical
context and delegates all lowering to the existing workers. Source01 originally
used f_scope(child); read-only review caught that its generic fallback does not
flatten Parallel. That snapshot remains unbuilt, and source02 contains the
approved correction. No host, core representation, normalizer, emitter or ABI
change was made.

| Gate | Result |
| --- | --- |
| Genuine checked B1 and guarded derivative | Pass |
| Maintained focused controls | 36 pass; existing 2 strict diagnostic differences retained |
| Saved stage observations | 8/16 exact, unchanged |
| Saved pattern observations | 71/114 exact, unchanged |
| New grouping observations | 49/66 exact, unchanged |
| Combined paired collection | 128/196 exact; every normalized outcome unchanged |
| Independent structural controls | 92/92 pass |

The paired collections were healthy: each side completed196 requests with no
worker errors, timeouts or unsupported results, and pinned-reference oracle
validation passed. Their **raw candidate oracle verdict is false**. The passing
audit means only no regression against the declared parent plus the structural
gates; it does not relabel the raw suite as passing. There are68 retained exact
differences:8 stage,43 pattern and17 new shape observations. Eight shape rows
are existing semantic mismatches: grouped local-body commas and three written
zero-head-match forms are wrongly accepted by the parent and this candidate.
The other nine shape differences are diagnostic differences. These controls
remain strict and are outside the previously reported main-corpus two-row gap.

The structural gate checks33 raw trees,33 successful-lowering boundaries,
24 complete successful lowered-book equalities, and2 Base equalities. Sixteen
FGroup nodes were observed across the33 raw fixture books; no marker survives
successful lowering. All24 successful fixture books are byte-identical to the
parent, including names, identifiers and source ranges. Base raw and lowered
books are also byte-identical, with zero wrappers. This is a node census, not
a heap-byte or performance measurement. No full frontend or timing gate was
run for this candidate.

The full source inventory contains61 Bend files and214 total parent/candidate
members. Exactly two source files differ. Physical Bend source lines increase
17,884→17,892 (+8); bytes621,438→621,948 (+510); function definitions1776→1777;
69 type declarations remain. The conceptual addition is one temporary syntax
marker and its completion helper, reusing the existing scope/flatten boundary.
No claim of reducing overall compiler complexity follows from this ablation.

Control preparation preserved two failed versions. Version01 incorrectly
expected the local callee and written zero-head matches to accept. Version02
corrected the written matches, but its revised callee still failed inference,
and matching a local binder was also rejected by upstream. Version03 records
callee parse acceptance/check rejection and local-match parse rejection.
These corrections were frozen before candidate source02 was built. No original
fixture, runner, failure report or consumed source snapshot was overwritten.

Evidence:

- [Source02 manifest and complete memberships](../../selfhost/build/phase17/group-source-02/manifest.json), with exact parser/elaborate patches alongside.
- [Checked attempt](../../selfhost/build/phase17/group-checked-01/attempt.json) and [focused gate](../../selfhost/build/phase17/group-checked-01/validation-001/report.json).
- [Frozen controls](../../selfhost/build/phase17/group-controls-03/manifest.json), [baseline](../../selfhost/build/phase17/group-baseline-03/report.json), [candidate](../../selfhost/build/phase17/group-validation-01/report.json).
- [Structural gate and process health](../../selfhost/build/phase17/group-direct-01/report.json), with raw trees and detailed assertions in its controls directory.
- [Independent comparison and lineage audit](../../selfhost/build/phase17/group-audit-01/report.json).

CPU3 was used for all owner compiler/probe jobs; those jobs are closed. The root
review accepted this as groundwork only. A concrete failure-checkpoint transport
proposal is the next research step; no production promotion is requested.
