# A bootstrap error was spending its time printing

Attempt02 failed its 120-second bootstrap child deadline. This initially looked
like a checking or emission regression after adding the scalar-region analyzer.
The bounded per-definition probe showed otherwise: all 42 analyzer definitions
checked quickly, and checking rejected `j_nat_loop_region` after about 1.9 seconds.
Its `+fast = KDef{...}` local needed an explicit `KDef` type annotation. Upstream
`err_show` then strongly normalized the observed constructor and context while
trying to explain that mistake. Printing the rejection consumed the deadline.
The original timeout remains failed; it is not a slow compiler-throughput
measurement. Parent corrected the source annotation in the next attempt.

Following the [prospective design](../../design/phase30/bootstrap-diagnostic-bound.md),
the bootstrap-only `stage0-library.mjs` now prints an unnormalized structural
summary. It includes a string expectation or term head, named holes, definition,
source line and column, a bounded source excerpt and note. It neither evaluates
terms nor traverses the cyclic source book/context. Ordinary non-Err exceptions
and the successful checking/emission path are unchanged. This reduces diagnostic
detail deliberately; ordinary self-hosted compiler diagnostics are unaffected.

Eight scoped controls passed in `selfhost/build/phase30/inspection-bootstrap-controls-01/`:

| Observation | Result |
| --- | --- |
| Frozen attempt02 source through changed helper | Same constructor error, no module published, 1.836 seconds |
| Successful old/new selected library | Emitted bytes identical; both completed in about 0.61 seconds |
| Actual emitted exports | Selected dependency, U32 wrapping and 10,000-step Nat recursion pass |
| Parse/type/named-hole/missing-export errors | All reject without publishing; each 0.45–0.61 seconds |
| Input identity recheck | All consumed files unchanged |

These are diagnostic-loop observations on CPU5, not clean speed benchmarks. The
full frozen failing source used a 10-second child deadline with the new helper;
the original development attempt used a 120-second bootstrap-child deadline.
The successful-byte control proves the chosen library is unchanged, not universal
compiler equivalence. The implementation changes only the error catch branch.

Independent static review found one location edge after the first control run:
at offset zero in a source beginning with a newline, JavaScript's `lastIndexOf`
can report the first newline despite a negative starting position. An explicit
zero-offset case corrects the column. Four focused formatter controls then passed
in `inspection-bootstrap-format-01`: that edge, ordinary line/column reporting,
named holes and a large error with cyclic metadata. They exercise the maintained
formatter source without invoking the compiler. The original eight-control
receipt and its exact earlier helper identity remain unchanged.

Reproduce the controls from the repository root with a fresh output directory:

```sh
taskset -c 5 /home/ai/.nvm/versions/node/v24.18.0/bin/node \
  selfhost/tools/performance/phase30/inspect-bootstrap-diagnostic.mjs \
  selfhost/build/phase30/inspection-bootstrap-controls-NEW \
  selfhost/build/phase30/attempt-02/snapshot/build/typed/snapshots/7f836d50b9ea020ce6739843b38ef610e0ce91aa1ea086c578f4c7dd470125ab/compiler.bend
```

The control tool freezes both adapter versions and fixtures, records upstream
source identities and each subprocess outcome, and retains all stderr. The
initial localization receipt is `inspection-bootstrap-diagnostic-01/report.json`;
it also preserves the 60-second instrumented timeout and a failed diagnostic
serialization probe, which exposed the source-book cycle. Reproduction currently
requires the retained ignored attempt02 snapshot; those full snapshot bytes are
not made durable by these links or hashes alone. Its mistake can alternatively
be reconstructed by assembling the attempt02 source modules and leaving the
worker's `fast` constructor binding unannotated.

## Reviewed recipe admission

Attempt04 generated a genuine checked API, then the equality derivative refused
the unreviewed changed bootstrap helper. That fail-closed result was expected.
Following the prospective amendment, `tools/development/equality.mjs` now accepts
exactly the old and new stage0/assembler hash bundles for the existing Phase23
pin. The new stage0 hash is
`c7eaf78482d64959d413ac490315d20f79c6cbd4f0ef6bb492ca7589d851f017`;
the assembler is unchanged. Other upstream profiles retain their original exact
bundle. No generated transformation or transformation version changed.

Independent static review approved the bundle check. All 19 controls passed in
`inspection-recipe-admission-01`: both Phase23 bundles derive and replay, output
bytes and statistics match the unchanged version6 transformation, changed/missing/
duplicate/misclassified recipes and unverified provenance reject before output,
historical versions2–5 replay exactly, and the new helper remains rejected under
the historical pin. The control tool is `inspect-recipe-admission.mjs`.

The existing `equality.test.mjs` was also run against its historical version5
compiler input. It reports 11 passes and five failures: three stale rejection
message expectations, one marshalling mutation aimed at an absent `f_parse`
export, and one attempted call to that missing export. Running the exact same
test against the unchanged pre-edit equality tool reproduced the same passing
and failing case names. Those suite failures remain visible; the recipe update
does not claim an all-green existing suite. Receipts are
`inspection-equality-historical-01.json` and
`inspection-equality-baseline-01/report.json`.
