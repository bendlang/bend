# Phase25 evidence and reproduction

Start with [the report](generated-code-analysis.md) and
[the prospective design](../../design/phase25/generated-code-analysis.md).
The compiler is unchanged; these tools analyze execution of emitted JavaScript.

## Requirements

- Node24.18.0 (the AST tool explicitly checks its embedded Acorn8.16.0).
- Python3, Linux `taskset`, available CPU3, and the checked Phase24 release.
- The clean pinned checkout at `selfhost/.bootstrap/upstream-phase23`, commit
  `018751270e800bc222a93dad7f257083ee53a5f7`.
- Optional Matplotlib for regenerating figures; no parser package installation.

Run commands below from the repository root. Put the correct Node binary on PATH;
set `PHASE25_NODE` to its absolute path to override the archived machine's default.
The release and pin are deliberately checked by the full acquisition tool.
Its input identities distinguish replay of this phase from a new compiler study.

## Reproduce the full current-image screen

Use new output directories for every attempt. Existing evidence is never resumed
or overwritten; failed runs retain their logs.

```sh
python3 selfhost/tools/performance/phase25/campaign.py acquire selfhost/build/phase25/replay-corpus
python3 selfhost/tools/performance/phase25/campaign.py calibrate selfhost/build/phase25/replay-corpus selfhost/build/phase25/replay-calibration
python3 selfhost/tools/performance/phase25/campaign.py measure selfhost/build/phase25/replay-corpus selfhost/build/phase25/replay-calibration/schedule.json selfhost/build/phase25/replay-timing
node selfhost/tools/performance/phase25/structure.mjs --manifest selfhost/build/phase25/replay-corpus/manifest.json --out selfhost/build/phase25/replay-structure.json
python3 selfhost/tools/performance/phase25/diagnose.py selfhost/build/phase25/replay-corpus selfhost/build/phase25/replay-timing selfhost/build/phase25/replay-diagnostics
python3 selfhost/tools/performance/phase25/traces.py selfhost/build/phase25/replay-diagnostics selfhost/build/phase25/replay-traces
python3 selfhost/tools/performance/phase25/summarize.py selfhost/build/phase25/replay-timing selfhost/build/phase25/replay-figures
```

Run CPU-intensive tools serially around the timing step. The static tool's full
JSON is approximately57MB (55MiB); compress it after verifying byte-exact recovery.
Sampling results naturally vary. Identical generated hashes also depend on source
and Base paths because ordinary libraries retain some absolute foreign paths.

## Fast one-case loop

Create a JSON config, for example:

```json
{"size":256,"seed":18,"expected":24132,"exportName":"bench","warmup":8,"warmupMs":100}
```

Use the actual independent `expected` from the chosen corpus entry rather than
copying an unrelated example. The numeric-table point's retained config under
`timing-01/pinned-u32-table-1/config.json` is authoritative. For arbitrary cases,
use `corpus/metadata.json` and its independent oracle implementation.

```sh
python3 selfhost/tools/performance/phase25/compare.py UPSTREAM.mjs CANDIDATE.mjs CONFIG.json NEW_RESULT_DIRECTORY
```

This command checks the scalar result, calibrates each output, warms each fresh
process and runs five alternating samples per side. It reports time per call,
both repetition counts and all raw process observations. It does **not** check
the source or compiler lineage: compile identical source using an identified
checked candidate and pinned reference first. A changed compiler should be built
with the [checked workflow](../../docs/PHASE5_DEVELOPMENT.md); the unchanged
`typed-driver.mjs` library mode supports that attempt's API/runtime/Base paths.
Do not use the full-acquisition Phase24 identity guard to relabel a new compiler.

The same tools accept restored saved modules for an immediate code-generation
study. See [archive recovery](evidence/README.md). The retained focused acquisition
used the original numeric-table config and completed in5.37s; this does not include
building a candidate compiler or recompiling a changed source.

## Reading the results

- [timing-summary.json](timing-summary.json), [CSV](timing.csv): all45 points,
  five raw times per output, repetitions, import observations and RSS.
- [measurement review](measurement-review.md): independent recomputation and limits.
- [structural summary](structure-summary.json), [notes](structure-notes.md): exact
  boundaries, corpus-common registrations, syntax families and source examples.
- [dynamic findings](dynamic-findings.md), [diagnostic tool](diagnostics-notes.md):
  exact operations versus sampled allocations/CPU, correctly normalized.
- [trace summary](trace-summary.json): reconciled original logs, including retained
  parser failures; no trace duration enters the timing comparison.
- [corpus notes](corpus-notes.md): independent checksums, unsafe-helper scope,
  fixture origins and preserved failed source attempts.

All displayed ratios compare execution of the emitted programs, not the speed
of the two compilers that emitted them. Source-shape groups are discovery aids,
not proofs of semantic equivalence. No code-generation optimization is promoted.
