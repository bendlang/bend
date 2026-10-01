# Phase35 generated-program optimization tools

Run from the repository root, with Node 24.18.0 available. Root runs all compiler,
timing and control jobs **serially**; never overlap profiles or source acquisition
with timing. Use fresh output directories. The maintained
[program suite](../programs/README.md) owns the 20/60/300/600-second iteration loop;
its [diagnostics guide](../programs/DIAGNOSTICS.md) covers CPU/allocation profiles
and generated-code comparison. Phase35 adds experiments and final admission,
not a second general benchmark suite.

## Prepare once and reuse

```sh
python3 selfhost/tools/performance/programs/prepare.py --attempt ATTEMPT \
  --set full --out NEW_PREP
python3 selfhost/tools/performance/programs/run.py --budget 60 \
  --cases local-pair,local-fold,symreg --candidate NEW_PREP/manifest.json \
  --out NEW_SCREEN
python3 selfhost/tools/performance/programs/run.py --budget 600 --set full \
  --candidate NEW_PREP/manifest.json --out NEW_CONFIRM
```

An existing complete preparation from the same checked API/runtime/Base can be
reused; a compiler change needs a new checked attempt and preparation. Controls
for new source fixtures always emit fresh checked modules. Timing reports retain
their own baseline and pinned TypeScript observations; do not combine medians
from separate runs to calculate incremental gains.

## Actual compiler owner controls and final gates

The parameterized plan supplies concrete owner acquisition/cohort commands,
resource supervision and final-API provenance checks. With both new modules:

```sh
python3 selfhost/tools/performance/phase35/final-integration-plan.py ATTEMPT NEW_PLAN \
  --added-module src/back/js/jpure.bend --added-module src/back/js/fold.bend \
  --prepared NEW_PREP/manifest.json
python3 selfhost/tools/performance/phase35/final-integration-run.py NEW_PLAN \
  --stage preinstall --out NEW_LAUNCH
python3 selfhost/tools/performance/phase35/final-gate-audit-v2.py NEW_PLAN NEW_AUDIT \
  --require-closed
```

`preinstall` runs owners first, then the broader inherited gates, and stops on the
first failure. `--stage owner` selects only owners. After that succeeds,
`--stage preinstall --start frontend-main --out NEW_LAUNCH_2` continues without
repeating successful owners. Repairs retain the original failed output and
require a new frozen plan. No installation occurs in these stages. After separate
performance admission, root runs `--stage postinstall` and a fresh audit with
`--post-install`. The exact counts and rules are in the
[admission design](../../../../design/phase35/prospective-admission.md).

| Owner family | Actual checked-output tools |
| --- | --- |
| Pair/fold state and events | `vector-cohort.py`, `vector-pair-controls.mjs`, `vector-fold-controls.mjs`, `vector-inline-order-controls.mjs` |
| Alias, nested state and counter refusals | `vector-acquire.py`, `vector-alias-controls.mjs`, `vector-nested-controls.mjs`, `vector-counter-fixture-controls.mjs` |
| Counter host hooks and bounded large Nat | `vector-countdown-controls.mjs` |
| Finite Nat, final Bool, residual purity | `region-acquire.py`, `region-controls.mjs`, `region-nat-guards.mjs`, `region-pure-guards.mjs` |
| Ray, Hit fields and inactive column tree | `region-ray-cohort.py`, `region-colf-cohort.py`, `region-extra-acquire.py`, `region-extra-controls.mjs` |
| Recursive structural folds | `fold-final-controls.py`, `fold-controls.mjs`, `fold-guards.mjs` |
| Aggregate and final-image audit | `final-owner-close.py`, `final-gate-audit-v2.py` |

The plan also binds existing scope/vector/primitive/worker/corpus/backend controls
to the selected API. Use its emitted commands when running individual owners;
some acquisition tools already own the shared execution lock. Do not wrap them
inside another locked supervisor.

## Compiler cost, separate from generated-program time

```sh
python3 selfhost/tools/performance/phase35/compiler-cost-plan.py \
  ATTEMPT NEW_PREP/manifest.json NEW_COST_PLAN --cases local-pair,mandelbrot
python3 selfhost/tools/performance/phase35/compiler-cost-run.py \
  NEW_COST_PLAN/config.json NEW_COST_RUN
```

Repeat with fresh directories for `--cases symreg,raytrace`, or omit `--cases` for
all four. These use unchanged maintained normal checked-library worker semantics,
validated per-compiler Base caches, pinned TypeScript, exact expected output and
three rotated fresh processes. They report import, request and process boundaries
separately. `compiler-cost-bindings.mjs` only verifies and records compiler/cache
identities; it is not an emission-only timing substitute.

## Historical output mechanisms

`vector-prototype.mjs`, `vector-countdown.mjs`, `vector-native-call.mjs`,
`region-selector-derive.mjs`, `branch-derive.mjs`, `region-colf-derive.mjs`, and
`sum-derive*.mjs` rewrite frozen generated JavaScript to test mechanisms quickly.
They are explicitly unchecked output prototypes, not compiler certification.
Their exact input hashes and consumed producer versions are recorded alongside
their outputs. `*-v1`, `*-v2`, and other archived versions preserve failed or
superseded attempts; use the frozen producer named by a historical report to
reproduce it. The unsuffixed owner tools above test actual emitted compiler code.

See [P35-001](../../../../experiments/phase35/P35-001-private-state.md),
[P35-002](../../../../experiments/phase35/P35-002-direct-regions.md) and
[P35-003](../../../../experiments/phase35/P35-003-private-folds.md) for hypotheses,
rejected alternatives and measured scope. A prototype gain or focused screen
does not establish conformance, steady-state performance or release admission.

For an interrupted owner run, `final-owner-retry-plan.py` creates a new owner-only
plan with an explicit failed-stage/output mapping and hashes the retained failure.
It preserves successful report paths and all original assertions. `--report
GROUP=EXISTING_REPORT` records an explicit metadata-only pointer repair when a
control succeeded but its collector path was wrong. Run the new retry plan with
`--stage owner`; resume broad gates from the original plan with `--start
frontend-main`. Audit the original plan with `--owner-controls
RETRY_PLAN/owner-report.json`. Never overwrite the original plan, failed output or
successful receipts.

The original `final-gate-audit.py` is preserved because existing plans pin its
bytes. The v2 successor resolves only the exact frozen reference bundle's old
installed compiler locations through checked historical snapshots; live final
candidate inputs still require their exact recorded bytes. See the
[audit repair report](../../../../implementation/phase35/provenance-audit-repair.md).
