# Generated-program execution

Status: **measured**; 15/15 selected cases complete.

Times include export invocation, exact result validation and checksum work; import and first calls are separate.
The budget is a maximum wall time, not a request to pad a short run. Short warmups are screens, not steady-state evidence.

| Case | Paired rounds | Baseline ms | Candidate ms | TypeScript ms | Candidate / TS (or baseline / TS) |
|---|---:|---:|---:|---:|---:|
| local-pair | 5/5 | 5.04621 | 3.81024 | 1.2459 | 3.058× |
| local-fold | 5/5 | 0.330214 | 0.139925 | 0.0400119 | 3.497× |
| scalar-region-0 | 5/5 | 0.00520445 | 0.00478043 | 9.36779e-05 | 51.030× |
| scalar-region-8192 | 5/5 | 0.14093 | 0.140255 | 0.0997896 | 1.406× |
| complete-generic-row32 | 5/5 | 0.457966 | 0.501585 | 0.00828796 | 60.520× |
| mandelbrot | 5/5 | 0.209371 | 0.208803 | 0.0456547 | 4.574× |
| editdist | 5/5 | 20.7004 | 16.201 | 4.97191 | 3.259× |
| tree-bitonic | 5/5 | 25.3435 | 25.3934 | 0.301794 | 84.142× |
| lexer | 5/5 | 176.709 | 172.003 | 1.92937 | 89.150× |
| symreg | 5/5 | 106.609 | 15.5288 | 1.10753 | 14.021× |
| test-morning-program | 5/5 | 0.230013 | 0.229581 | 0.00368629 | 62.280× |
| test-evening-program | 5/5 | 0.180967 | 0.159571 | 0.00303196 | 52.630× |
| test-rle-roundtrip | 5/5 | 0.0467512 | 0.0466503 | 0.000601261 | 77.588× |
| test-map-set-ops | 5/5 | 1.63067 | 1.6245 | 0.0224701 | 72.296× |
| raytrace | 3/3 | 10291.4 | 1879.84 | 34.3154 | 54.781× |

Missing, failed and partial samples remain in report.json; incomplete cases have no comparison ratio.
Output agreement on these fixed inputs is not a full conformance gate. No historical timing is used as a denominator.
