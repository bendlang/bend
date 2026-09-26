# S4 B: bounded ordinary graph-loading cost gate

Status: prepared before execution. Do not run while the checked self-hosting proof
or another CPU 0 validation/benchmark is active. This measures the loader route
changed by B; the parent separately owns the accepted/rejected full-host checker
experiment and full frontend preservation.

Use A02's default equality-derived API as baseline and B01's default
equality-derived API as candidate, through their checked attempt manifests.
`verifyAttempt` verifies their genuine checked bootstrap and exact derivation
lineage before and after the experiment. No compiler build, injected export,
runtime rewrite or historical timing row is used.

The fixture is the same real four-core assembly used by the S3 performance pilot:
`selfhost/build/phase4/private/component/core.bend`, **60,909 bytes**, SHA256
`7ea730ae3e2ee190ff55a0def12f8410203fee9fa2c0573df52265b583523ccf`.
It imports the actual pinned canonical Base, SHA256
`b8c2734d45ec6b4ce70fee70ff06ef35e08fce885af8852d8eb77dbff020e946`.
This is a bounded real compiler workload, not the full compiler source or a
synthetic repetition of trivial declarations. The newer core-pilot baseline is
61,004 bytes (`f997…d659`); it is a separate source and is deliberately not mixed
into these measurements.

Every fresh worker imports only its assigned API. It parses Base with that API
and wraps it as `FParsedSource` before requests. Base is **not** a seeded loaded
book. Both workloads call ordinary `f_load_graph` and therefore exercise the
unseeded worker now shared with seed loading:

- `raw`: core is an `FSource`; Base is already parsed.
- `parsed`: core and Base are both parsed by the assigned API before requests.

Before any timing, two separate oracle processes load both modes and save the
complete graph and trace objects as JSON. Require successful loading, exact
`trace.result === graph` by deep comparison, exact raw/parsed graph equivalence,
unchanged input structures, identical cross-version prepared inputs, and byte
equality of each cross-version graph/trace JSON. Do not sort declaration events,
normalize binder IDs, reduce to an acceptance flag or omit the trace's sources.
The oracle is the frozen A02 behavior; this is not a new upstream conformance
measurement.

Run two ABBA blocks for each mode, serially on CPU 0: A B B A A B B A. Each of the
16 timing workers is a fresh Node process, fixed stack 4 MiB and heap 4 GiB,
with inherited `NODE_OPTIONS` and `BEND_*` settings cleared. The same process-local
prepared sources serve its requests. One initial exact-result check and three
warmup requests precede forced GC; five whole requests form the timed batch.
Parsing preparation, API import, oracle checks, GC and JSON/hash work are outside
that batch. Automatic GC during the requests remains included. Check the final
complete graph against the saved oracle and recheck source immutability.

The runtime statistic is the median of four independent per-process batch means
per variant/mode. Record every batch's wall time and CPU time; do not select the
fastest result. Runtime guard: candidate/baseline **≤1.05** for both modes. Memory
guard: ratio of median process peak RSS **≤1.10** for both modes. Peak RSS is
recorded before final-result serialization and includes module import, parsing,
warmup and requests; it is a process footprint, not an isolated allocation count.
Worker provenance hashing uses 64 KiB streaming reads so hashing the 118 MiB Node
executable cannot create a full-file Buffer allocation that floors the RSS gate.
Record pre/post-timing RSS as context. The default selected API byte-size ratio
must also be **≤1.10**. Preserve complete failed or near-threshold measurements;
do not quietly relabel them as passing or drop outliers. A repeated experiment,
if needed, requires a fresh directory and an explicit explanation.

All children have file-backed stdout/stderr and a 120-second bound. The experiment
has a 15-minute success deadline, with no concurrent workers. Each child is also
limited to the remaining experiment time; final synchronous provenance checks may
finish after that deadline but must then reject the experiment as incomplete.
This is not an outer hard-kill timer for the orchestration process. It stops at the first
failed oracle, changed input, child error or exhausted deadline and preserves
the incomplete report. A guard failure sets `complete:true, pass:false`; a
measurement failure remains incomplete. API/source/runner/Node/config identities
and attempt verification are checked again at the end.

After the parent confirms the proof has finished and B01 is checked:

```sh
/home/ai/.nvm/versions/node/v24.18.0/bin/node implementation/phase7/s4-evidence/graph-cost.mjs \
  selfhost/build/phase7/s4/attempt-a02 \
  selfhost/build/phase7/s4/attempt-b01 \
  selfhost/build/phase4/private/component/core.bend \
  selfhost/build/phase7/s4/graph-cost-01
```

The output directory must not already exist. This gate does not establish total
iteration latency, rejected-program cost, seeded-loader cost, native execution,
fixed-point correctness or speed relative to TypeScript. Those retain their
separate controls; no focused ratio is promoted to a whole-compiler claim.
