# Generated-program execution

Status: **measured**; 3/3 selected cases complete.

Times include export invocation, exact result validation and checksum work; import and first calls are separate.
The budget is a maximum wall time, not a request to pad a short run. Short warmups are screens, not steady-state evidence.

| Case | Paired rounds | Baseline ms | Candidate ms | TypeScript ms | Candidate / TS (or baseline / TS) |
|---|---:|---:|---:|---:|---:|
| local-pair | 3/3 | 5.06962 | 3.87132 | 1.27984 | 3.025× |
| local-fold | 3/3 | 0.377166 | 0.146761 | 0.0718606 | 2.042× |
| symreg | 3/3 | 123.336 | 17.4033 | 1.26816 | 13.723× |

Missing, failed and partial samples remain in report.json; incomplete cases have no comparison ratio.
Output agreement on these fixed inputs is not a full conformance gate. No historical timing is used as a denominator.
