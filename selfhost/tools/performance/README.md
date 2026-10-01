# Explicit-artifact performance comparisons

For **execution speed of generated programs**, start with
[`programs/README.md`](programs/README.md). Its maintained runner has
20 / 60 / 300 / 600-second budgets and separates checked candidate preparation
from repeated execution. The tools below measure **compiler requests**.

`compare.py CONFIG.json NEW_OUTPUT_DIR` runs independent Node processes serially
on a specified logical CPU. Each repetition rotates the variant order. The JSON
report records raw phase timings, CPU time, peak RSS, process wall time, output
hashes and input hashes; generated programs are executed outside compile timing.
No warmup runs or results are silently discarded. Use at least seven repetitions
for small workloads. A full compiler run may use fewer, explicitly reported.

Example (replace paths with absolute local paths):

```json
{
  "node": "/path/to/node",
  "upstream": "/path/to/pinned/upstream",
  "cpu": 2,
  "flags": ["--stack-size=4096", "--max-old-space-size=4096"],
  "repetitions": 7,
  "timeout": 180,
  "variants": [
    {"name": "upstream", "kind": "upstream"},
    {"name": "candidate", "kind": "bend", "api": "/path/to/stage2.mjs",
     "runtime": "/path/to/runtime.mjs", "driver": "/path/to/typed-driver.mjs"}
  ],
  "workloads": [
    {"id": "base-u32", "input": "/path/to/base-u32.bend",
     "mode": "compile", "expected": "42", "caches": ["off", "cold", "warm"]}
  ]
}
```

The upstream checkout must be clean and exactly the revision in `src/compiler.json`.
Every variant receives that checkout's Base file. `off` disables both Base seed
and prefix reuse. `cold` clears generated Base cache files immediately before
measurement. `warm` clears and primes in a separate fresh process whose work is
recorded under `primes`; the measured process then loads that cache. Upstream
has no equivalent persistent Base cache and runs only under `off`.
Cache directories belong to each explicit driver; do not share them with a
concurrent build. Freeze separate hosts for concurrently needed artifacts.

`check`, `parse`, `compile` and `library` are supported. Library validation checks
JavaScript syntax only; a complete checked fixed point must be run separately.
The full-compiler benchmark must use the same frozen source for control and
candidate. A candidate's own changed source belongs to its separate self-hosting
proof. `sourceFiles` on a Bend variant adds files to the immutable input manifest.
`reportDeclarations` enables CLI declaration-report work, normally disabled in
pipeline measurements. Process time includes imports, startup and output writing;
`compileMs` excludes those and generated-program execution. Phase boundaries of
upstream and the Bend compiler differ and must not be divided as equivalent work.

Results include all failures and min/median/max; inspect per-case time, RSS and
output size before accepting a change. A timed-out or failed sample cannot become
a speedup result. CPU affinity does not isolate a physical core, its SMT sibling,
memory bandwidth or system load: record concurrent activity and avoid overlapping
benchmarks. Hash verification rejects changed inputs after a run.

For profiles, use a separate run with Node CPU profiling flags in `flags` and an
absolute writable profile directory. Never compare a profiled candidate against
an unprofiled control as the primary performance result. The original
[`run.py` workflow](BASELINE.md) and committed September 21 baseline remain
historical controls. Run that workflow from the baseline tag, whose archive
manifest is intentionally immutable.
