# Checked17 selected backend pilot

The pilot retains **81 exact historical observations:69 paired fixture passes,
8 not-applicable compile refusals and4 shared check failures**. Of these,
54 interpreter/JavaScript observations were freshly acquired on checked17;
27 check/native observations are explicitly reused from checked16 after an
independent executable-dependency audit. This is not81 new17 executions or full
backend conformance. The optional811 new-JS campaign remains unexecuted.

| Lane | Rows | Evidence on17 |
| --- | ---: | --- |
| Check |4 | Reused unchanged16 frontend; four raw shared failures retained |
| Interpreter |28 | All freshly acquired17, including possible IO→JS paths |
| JavaScript |26 | All freshly acquired17 with the changed runtime |
| Native CPU |23 | Reused unchanged16 native dependencies; original approved execution context retained |

The fresh54 acquisition completed in58.888 seconds with all full reference and
candidate observations exactly matching their named historical rows. It used
the unchanged Phase24 helper and batches1,2,4,5 (zero-based), four workers on
CPU3–6, original30-second probe limits, the same fixtures/oracles and fresh
output paths. The450-second outer cap did not fire. There were no incomplete or
never-started rows, changed inputs, new host errors or discarded observations.
These durations describe acquisition, not a controlled speed result.

The [independent reuse audit](registration-flag-actual-review.md) proves the
compiler API, genuine parent, assembled Bend source, Base, all65 modules,
ordered manifest, host/adapter and native runtime unchanged. Its27 selected
historical rows exclude both interpreter and JS. Static review caught that IO
interpreter requests can execute generated JavaScript, so all28 interpreter
rows were renewed rather than silently treating their lane name as proof that
the changed runtime is unused.

Canonical evidence under selfhost/build/phase30 is
backend-pilot-renewed-17/{plan,report}.json, its four batch directories and their
verified archives; review-registration-reuse-17/report.json binds the27 reused
rows and their original receipts. The runner saves attempted/observed rows
before comparison and keeps incomplete versus never-started selections separate.
Complete raw result objects, verdicts and agreement flags are compared with
type-sensitive canonical JSON equality. Named NA/check failures remain their
original classifications; other paired errors would fail this gate.

The earlier16 wrapper classification failure and default-environment Clang EPERM
attempts remain preserved in the [16 report](backend-pilot-renewal.md). The17
native claim rests on16's successful unchanged selection in the explicitly
approved execution context, never on matching EPERM errors or an assumption
that the default environment was repaired. New installation and42-step smoke
require their own selected-image receipt.
