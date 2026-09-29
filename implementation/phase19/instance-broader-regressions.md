# Original broader regressions after live-instance checking

Original frozen selections were run without changing their bytes or strict oracle. The immutable Phase19 paired runner used final checked `instance-build-03` on CPU1. These are supplementary observations; the frozen owned compiler report remains unchanged.

| Selection | Previous exact | Final exact | Newly exact | Lost exact | Changed primitive records |
|---|---:|---:|---:|---:|---:|
| integration198 | 197/198 | 198/198 | 1 | 0 | 0 |
| group196 | 128/196 | 128/196 | 0 | 0 | 0 |

The immutable runner overall flag also requires every verdict to be `pass`; negative parse lanes intentionally receive `observed`, even when every result byte matches the pin. The grouped run additionally stops at its strict selected-completion assertion after collecting all196 healthy rows, because nine inherited acceptance-contract failures remain. The raw incomplete/false gate flags and per-side verdict census remain in the machine report. They are not rewritten. A separate complete-acquisition audit verifies both vectors have all expected rows with no worker errors, timeout, crash or unsupported execution.

The grouped historical baseline03 and validation01 candidate records are identical. Reference replay changes: 0.

Full paired result changes and every remaining strict mismatch are retained in [the machine report](instance-broader-regressions.json). The broader regression comparison and strict conformance are distinct results; inherited mismatches are not waived or represented as passing.

Newly exact observations:
- `program-completion/same-body-known-gap` (check)

Evidence: `selfhost/build/phase19/instance-integration198-01/` and `instance-group196-01/`, each with original selection, checked API/cache identities, complete candidate/reference vectors and paired rows.
