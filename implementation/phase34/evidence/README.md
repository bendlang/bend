# Phase34 diagnostic evidence

[validation.tar.gz](validation.tar.gz) preserves the closed contents of
`selfhost/build/program-diagnostics`, excluding Python bytecode caches.
The [inventory](manifest.json) records every member's SHA256, size and mode:
**897 files / 420,435,477 logical bytes**, compressed to **26,796,933 bytes**.
The streaming [capture script](preserve.py) reopened the archive and checked every
member, then rehashed source files to detect changes during capture. All benchmark
and control processes had finished before capture; none ran during archiving.

Archive SHA256:
`7cce90d7f19e18cc759b3dc7aaffa690a568a9d3823938fdc99efd4cc73eab14`.

Contents include:

- `fast-01`: the initial allocation-accounting failure, its raw V8 sample and all
  earlier completed profiles. It is deliberately incomplete.
- `fast-02`: all thirty successful CPU/allocation profiles for five points and
  three roles, using exact copies of previously timed modules.
- `full-01`: all sixty profiles for fifteen points / two roles, full AST inventory,
  normalized token files, and side-by-side HTML. The original 32 KiB raytrace
  allocation capture remains unchanged, including its high memory receipt.
- `raytrace-memory-01`: the separate 256 KiB allocation control for both roles,
  with lower observed profiler memory. Do not merge it into the original full run.
- `combined-01`: ordinary pair execution followed by four diagnostic profiles,
  with a frozen timing snapshot and separately recorded statuses and budgets.
- `controls`: initial/retry/final analyzer logs, Python runner/diagnostic test logs,
  final profiler logs and the initial profiler result summary.

Each run retains generated modules, consumed tool versions, plans, input hashes,
raw profiles, result checks, logs, resource receipts and incomplete coverage where
applicable. The initial profiler summary was transcribed from its tool output;
later test logs are retained directly. Temporary synthetic fixtures are not
captured. Test sources are committed alongside the maintained tools. Node/Python
binaries, original compiler installations and catalog source files are identified
by receipts rather than duplicated here.

The separate [closure summary](../validation-summary.json) checks that the
installed compiler still matches the Phase33 baseline and that diagnostics left
the combined run's timing cases and immutable snapshot unchanged. The
[protection audit](../protected-files.json) covers the 103 unrelated files.

Extract for inspection without overwriting a prior acquisition:

```sh
mkdir /tmp/bend-phase34-evidence
tar -xzf implementation/phase34/evidence/validation.tar.gz -C /tmp/bend-phase34-evidence
```

Open `full-01/report.md`, `full-01/analysis/comparison.html`, or import a raw
`.cpuprofile` / `.heapprofile` into a compatible viewer. Absolute paths in receipts
describe the acquisition machine; they are not portable replay dependencies.
Use the [maintained suite](../../../selfhost/tools/performance/programs/DIAGNOSTICS.md)
with a new output directory for new measurements.
