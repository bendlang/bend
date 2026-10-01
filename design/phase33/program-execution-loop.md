# Phase33: one reusable generated-program execution loop

The installed Phase32 compiler and pinned TypeScript compiler remain unchanged.
Make their generated JavaScript comparisons easy to run from a fresh checkout,
without requiring historical ignored build directories. This is benchmark tooling,
not a new compiler optimization or a claim of representative application speed.

Keep a catalog of fifteen existing points: complete pair, independent fold,
scalar zero/8192 and generic row canaries, plus the ten original programs. Preserve
source bytes, public arguments, exports and exact expected results. Bundle frozen
Phase32 and TypeScript modules with portable paths and SHA256 provenance. Candidate
preparation compiles selected fixtures once, outside execution budgets, from an
installed release or a checked attempt. Manual-JavaScript experiments must be
explicitly labeled prototypes, never checked compiler output.

One runner accepts 20, 60, 300 or 600 seconds of total execution wall budget and
an independent workload set or case list. Default sets progress from fast local
points to core original programs, broad coverage and the expensive ray tracer.
The deadline includes artifact verification, import, warmup and measurement;
compilation/preparation is separate. Requests exceeding their budget preserve
partial receipts and exit nonzero. The runner must never silently substitute a
smaller workload, discard a failure, or call missing observations passed.

Use fresh Node processes, rotating variant order, exact checks inside every call,
and separate import/first-call/warmup/calibration/timed observations. One process
per sample avoids repeating check/calibration startup three times in short runs.
Preset warmups and sample counts are explicit; slower points need bounded warmup
call floors. A short screen is not steady-state throughput or a conformance gate.
Only complete balanced rounds contribute comparison statistics. Preserve partial
samples too, and suppress speedup claims for failed/incomplete cases.

All heavy processes run serially, with CPU affinity, 1GiB Node heaps, process-tree
RSS limits, a 2GiB available-memory floor, deadline supervision and signal-safe
child cleanup. Share the existing execution lock so old experiment launchers
cannot overlap. Freeze exact plans and record raw samples, hashes, resources and
coverage in JSON plus a short Markdown table. No imported historical timing is
used as the fresh candidate's denominator.

Validate portable baseline recovery, installed/attempt preparation, all workload
entry points, meaningful wrong-result/tamper/deadline/memory/signal controls, and
actual execution of all four budget presets. Use the current compiler and retained
TypeScript outputs; no compiler source changes or broad frontend retesting are
required. Commit a README with copyable commands, workload membership, budget and
measurement limits, report interpretation and the old protocol boundary.
