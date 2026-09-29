# Backend evidence index

The canonical [backend report](../backend.md) states outcomes, failures and limits.
All directories below are immutable attempts under `selfhost/build/phase23/`:

| Directory | Observation |
| --- | --- |
| backend-scanner-01 | Sandbox child spawn EPERM |
| backend-scanner-02 | Invalid computed match in proposed scanner |
| backend-scanner-03 | Omitted small-build harness dependencies |
| backend-scanner-04 | Checked scanner; 4,116 regex comparisons pass |
| backend-new-01 | Initial 16 rows; four missing-atomic failures plus reference JS TCP limitation |
| backend-atomic-controls-01 | Invalid scoped fixture syntax retained; idle TCP and scheduler execute |
| backend-atomic-controls-02 | Real clone-order failure; float oracle comments wrong but actual atomic values exact |
| backend-final-new-01 | Final 16 candidate verdicts pass; 15 exact, one reference JS TCP limitation |
| backend-final-controls-01 | Final 8 candidate verdicts pass; 7 exact, one reference JS TCP limitation |
| backend-retained-arrays-01 | Retained 18/18 exact/pass |
| backend-native-threads-01 | 100 successful executions at worker counts 1/2/3/4 on cores 3–6 |
| backend-tsan-01 | GCC 10 cannot compile musttail; neither binary runs |
| backend-tsan-02 | Clang 16 compiles; incompatible GCC libtsan prevents linking either binary |
| harness-originals-01 | Original maintained test bytes before current-pin / ABI mock maintenance |
| harness-final-01 | All 114 maintained harness tests pass; full TAP and input hashes |
| component-originals-01 | Original runner and historical raw-parser fixture |
| component-fixture-originals-01/02/03 | Original low-level fixtures and package command |
| component-invocation-01/02 | Retired export / stale KEnv failures, with exact consumed helpers |
| component-focused-01 through -10 | Retained fixture maintenance failures and successes using the same checked API |
| component-invocation-03 | Final advertised npm command passes, no input drift |
| component-verify-01/02/03 | Full module snapshots and step reports; final 18/18 steps pass |

[scanner-01.json](scanner-01.json) contains the complete differential scanner
corpus. `js-tcp-01` and `js-tcp-02` retain failed harness attempts;
[js-tcp-03/report.json](js-tcp-03/report.json) records 16 passing host controls.
Their generated standalone sources are preserved beside each report.

Every paired directory contains request/response records, exact fixture hashes,
selected reference/candidate reports, copied consumed harnesses, stdout/stderr,
emitted sources and retained programs. Checked attempts combined-build-01/02/03
identify compiler/Base/runtime/tool inputs separately; do not infer a genuine
checked artifact from a derivative or from one successful runtime output.

Preservation packaging and recovery receipts are linked from the phase-wide
migration report. A build-directory path alone is not a durable evidence claim.
