# Independent S4E checked-loop review

Approve the **observed bounded loop-cost gate**, with the measurement and failure
limits below. This review ran no compiler, generated API, conformance worker or
benchmark. It read the frozen evidence and called the maintained `verifyAttempt`
on all four completed attempts using the recorded Node 24.18.0, on CPU 1.

## Inputs and independent checks

- Runner: [run.py](run.py), SHA-256
  `5731a2d4cf4d5b6d9b81347a86ba42edb7466d8915cadcb1867dfcf277fb3e93`.
- Result: `selfhost/build/phase7/s4-loop-02/report.json`, SHA-256
  `f8e9c5d8960522bbb145135f6f5248b020cd882cb51d6429dc7b86d9cb81b719`.
- Maintained workflow SHA-256:
  `a85428ae724a921511caec545831e4837a2e723ae9609eacef1166c05a5043ff`.
- All four `verifyAttempt` calls passed: checked bootstrap source/module/input
  identities, Node/Base/runtime, frozen files, checked API and exact equality
  derivation replay. This verification operates on artifact bytes, without
  executing compiler jobs.
- Each attempt is `checked: true`, `artifactKind: derived-b1`, and has the same
  55 ordered exports. Control and candidate APIs match their frozen expected
  checked/default hashes; this is not an unchecked bootstrap shortcut.
- All focused reports are complete/pass with 21 cases. Selection SHA-256 is
  `5fcd9a8c2556dae71d2eb0b6e9c4d3fce7ed2832bc66ddc0f22bcf5840d37717`.
  The complete ordered paired-result arrays are equal across all four runs.
  Each has semantic agreement on those cases and the same **seven exact
  diagnostic differences**; `strictExact` is false. A gate pass does not mean
  21 exact matches, full-language conformance or new semantic coverage.
- This reviewer recomputed both wall and RSS ratios from the recorded samples;
  they equal the report. Runner/workflow current hashes match their records.

Attempt manifest SHA-256 values, in ABBA order:

| Attempt | Manifest SHA-256 |
| --- | --- |
| `0-A` | `bb48ddd996d89fe49e651771b98d8209e4a7800f167fd81386ebb65195706da4` |
| `1-B` | `da2f8ac9b24ec60b92a33e429bc5428e13a9e27171c2a4d08720d8381d0f0348` |
| `2-B` | `80c01f0f18b9ef84efcc1a1a5767df5f6f613c5ff684e02d5cb1a5a87abf2034` |
| `3-A` | `3e5c65fd1fd18e950cdb2212d18e57f9d9e58f893814ff8e27c54f8d4cee18ae` |

## Timing and resource meaning

The runner serially executes A/B/B/A: frozen S3 baseline source and final B02
source, with fresh output directories and checked/equality/focused attempts.
Both use the same pinned upstream, maintained workflow, selection, one job,
CPU 0 affinity, 4,096 KiB Node stack and 4,096 MiB V8 heap limit. `BEND_*` and
`NODE_OPTIONS` are removed. The workflow makes its own fresh snapshots and Base
cache. The timed region includes workflow preparation, full compiler checked
bootstrap, equality derivation/verification and focused paired validation.
It also includes Python launch/wait overhead; it is not compiler execution time
alone. New attempts do not imply cold filesystem or processor caches.

| Pair | Control wall s | Candidate wall s | Wall ratio | Largest-process RSS ratio |
| --- | ---: | ---: | ---: | ---: |
| `0-A` / `1-B` | 35.1333 | 34.8835 | 0.99289 | 1.01934 |
| `3-A` / `2-B` | 34.8319 | 35.0836 | 1.00723 | 1.03298 |

Both observed pairs meet the predeclared **1.05 wall / 1.10 RSS** guards. This
is one ABBA block with two samples per variant, not repeated-block statistical
evidence of a speedup or a universal upper bound on future regressions. It
compares complete development loops, not Bend execution against TypeScript
execution; the checked bootstrap and paired oracle themselves use upstream.
No CPU-consumption counters were recorded.

Each sample starts a fresh Python worker and measures
`resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss` after waiting for its
workflow. This avoids carrying an earlier sample's high-water mark forward.
On Linux the value is **the largest individual waited-for child/descendant
process RSS high-water mark, in KiB**, not the simultaneous aggregate memory of
the process tree. The runner's shorthand "process tree" must not be read as
an aggregate tree-RSS measurement. See the [Linux `getrusage(2)` description](https://man7.org/linux/man-pages/man2/getrusage.2.html).
The Python worker itself is excluded; the workflow and descendants contribute
through waited-for usage propagation. V8 heap limits are not total RSS caps.

## Preserved failures and limits

The first launcher attempt is retained in `selfhost/build/phase7/s4-loop/`, with
its incomplete/failing report and `runner-attempt-01.py`. The archived script's
hash matches that first report. It failed before launching the workflow because
`/usr/bin/time` was absent; no timings from it enter the four successful samples.
The measured replacement runner remains unchanged.

The replacement runner is suitable as preserved one-off evidence, **not yet a
robust reusable timeout supervisor**. Its timeout branch kills the workflow's
process group, while maintained `process.mjs` starts descendant jobs in detached
groups. Its outer `subprocess.run` timeout can also kill only the Python worker,
leaving the workflow's separate session alive. The inner maintained supervisor
has its own descendant cleanup, but an outer kill can prevent that cleanup.
No timeout, overflow, signal or process error occurred in these four completed
samples, so this failure-path limitation does not invalidate their observed
guard results. Fix and test supervision before reusing this runner for hostile
or timeout-prone workloads; do not silently change the measured script.

The review's first summary-only inline script also had a bookkeeping error:
after all four `verifyAttempt` calls passed, it deleted the first row's export
array before comparing later rows. It wrote no files and ran no compiler. A
corrected read-only summary retained the expected array separately and passed
all identity, ordered-export, selection and ratio checks. Both invocations are
visible in the review tool transcript; no benchmark evidence was replaced.

This review approves only the recorded S4E gate. Broader S4 behavior evidence,
the A02 self-host proof, B02 source review and the unmet 50% simplification
milestone retain their separately documented scopes.
