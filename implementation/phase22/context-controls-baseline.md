# Independent baseline for contextual parser migration

The frozen public frontend suite completed 60 observations on installed Phase21 API 44094e58 and pin b2111cf: 27 exact, 33 strict differences and 11 primitive acceptance/phase differences. The raw suite remains false. All six ordinary programs parse and check exactly. Their separate check/interpreter/JavaScript/native suite is 24/24 exact, with outputs 8, 42, 12, 12, 11 and 105n. Six check observations overlap the two suites; these are not 84 independent cases.

The suite reuses 24 boundary fixtures from the saved broader 196, C1 and grouped-constructor controls, then adds five ordinary programs and one unchanged pinned do program. New programs distinguish simultaneous parallel RHS lookup from sequential binding, prior global names from new shadowing names, lexical lambda capture under a nested same-name local, erased and unrestricted quantities, and completed groups in both sides of an annotation. The earlier imported-alias/header-shadowing, grouped-constructor, raw/completed comma and first-error witnesses retain their original bytes.

Four reused constructor acceptance expectations still fail against the pinned parser. The upstream negative monad parse observation is an `observed` verdict, not an additional failed oracle. The inherited thin runner's field named `referenceOracleFailures` contains all non-pass entries; the final report distinguishes these four failures from the one observed result. No fixture, expected result or raw status was rewritten.

All inputs are frozen under `selfhost/build/phase22/context-controls-inputs-01`; complete outcomes are in `context-controls-baseline-01` and `context-controls-program-baseline-01`. The machine-readable `context-controls-baseline.json` binds fixtures, plans, selected sibling import files, old designs, tools and reports. Runs used CPU2, one worker, 4GiB heap and 4MiB stack. All jobs are closed; no migration candidate, compiler build or production edit was performed.

# Remaining observed frontier

The exact current broader 196 vector has 57 differing observations across 29 fixtures, grouped by source ownership as follows:

| Family | Observations |
| --- | ---: |
| Scoped local pattern before continuation |26 |
| Row/body/group flatten checkpoint order |8 |
| Marked-name/family admission |10 |
| Offload head classification |4 |
| Do completion before outer pattern/orphan return |4 |
| Raw body versus completed-group comma |2 |
| Group flatten before close delimiter |2 |
| Marked empty-call source range |1 |

Only the two original body-comma observations change primitive behavior within this particular 57; the other 55 differ in diagnostics. C1 and the independent grouped-constructor controls demonstrate additional acceptance/phase gaps outside that count. Main 2996's two do diagnostics already occur in the do family and must not be counted again.

A complete contextual parser could plausibly address all 57 without new type theory. This is a boundary estimate, not a promised patch yield: even the 38 local/row/group checkpoint-family observations require real lambda, All, header and alias scopes. The private Stage4 parser leaves several of those owners unsupported. Another 18 require marked/offload/do owners, and one needs exact marked-call origin preservation. The real closure gate is unchanged main 2996, broader 196, C1, independent constructor acceptance and ordinary emitted programs; closing only the two main-suite do rows would not establish full observed conformance.

Future candidate comparisons preserve every old exact match and the complete pinned observation protocol. A changed primitive outcome is allowed only when it becomes the pinned outcome. An Unsupported result, earlier unrelated rejection, changed oracle or normalization that hides a name/capture error cannot pass this gate.
