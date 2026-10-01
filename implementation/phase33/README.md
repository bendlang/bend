# Phase33: reusable generated-program execution benchmarks

The compiler stays at installed Phase32 checked03. This phase consolidates the
execution loop into [one maintained suite](../../selfhost/tools/performance/programs/README.md),
with a [prospective design](../../design/phase33/program-execution-loop.md), four
wall-budget presets and independent workload selection. Compilation is a separate,
reusable preparation step; timing never imports either compiler.

## What is committed

- Fifteen fixed points from thirteen byte-preserved Bend fixtures, grouped as
  `fast` (5), `core` (8), `broad` (14) and `full` (15).
- Fresh checked outputs from Phase32 and pinned TypeScript in a portable 413 KB
  compressed reference, with source/module/compiler identities and all acquisition
  logs, receipts and consumed tools. The pin remains
  `018751270e800bc222a93dad7f257083ee53a5f7`.
- `prepare.py` for installed or checked-attempt candidates, `run.py` for same-run
  comparisons, and `prototype.py` for explicitly unchecked manual-JavaScript
  hypotheses. The normal workflow never overwrites an earlier output directory.
- Serial fresh processes, rotating roles, exact result checks on every call,
  total deadlines, shared locking, heap/tree-RSS/headroom limits and signal cleanup.
  Every run retains its plan, raw observations, resource receipts and Markdown table.

## Validation

All four presets completed their requested coverage. Node 24.18.0, Linux, CPU 3,
serial execution; host/tool identities and every raw sample are retained.

| Budget / set | Roles | Coverage | Samples | Wall time | Peak tree RSS |
|---|---|---:|---:|---:|---:|
| [20s / fast](measurements/20s.md) | 3 | 5/5 | 45 | 16.39s | 70.8 MiB |
| [60s / core](measurements/60s.md) | 3 | 8/8 | 72 | 56.71s | 79.2 MiB |
| [300s / broad](measurements/300s.md) | 3 | 14/14 | 210 | 259.40s | 101.5 MiB |
| [600s / full](measurements/600s.md) | 2 | 15/15 | 146 | 351.07s | 132.4 MiB |

Three roles means pinned TypeScript, frozen baseline and checked candidate. The
600-second validation uses TypeScript and baseline; adding a candidate consumes
additional budget and may require narrowing the selection on slower hosts. Every
case retained its original input. The 300-second same-compiler baseline/candidate
median ratios ranged from 0.987 to 1.020, illustrating noise even without an
optimization. None of these four successful runs exceeded its budget.

The relocated reference passes **30/30 role/point combinations** in 34.36 seconds.
Node filesystem permissions allow reads and writes only inside the new portable
root; a negative witness confirms that reading the original repository fails with
`ERR_ACCESS_DENIED`. Thus the selected entry points do not need the dormant Base
foreign paths or ignored build directories. This is an execution smoke check,
not an additional timing comparison.

The prototype utility passes an unchanged-computation control and rejects a
replacement returning the wrong result at its first call, with no ratio. An
intentionally undersized `--budget 20 --cases raytrace` run reports
`budget-exhausted`, 0/1 completed cases and no ratio. It takes **20.49 seconds**
including 0.49 seconds of cleanup, postflight identity checks and final reporting.
No selected input was reduced. The normal four preset runs have zero overrun.

An explicit post-acquisition audit confirms the catalog source and emitted module
hashes of all **42 checked emissions**, including the final hardened fast-set
preparation. Raw observations and the original/final consumed tools are in the
[verified evidence capsule](evidence/README.md); readable measurement tables are
linked above.

The installed and checked-attempt APIs have identical SHA256
`8be506d811f627fe6346a5eaba07050c36db70e2704608adcfd781b85a3a7f92`.
Their generated modules differ by Base directory strings for dormant foreign
functions. All fifteen match after diagnostic normalization of those paths;
measured modules remain unmodified. This validates two acquisition paths for the
same compiler, not an optimization. Differences between their measured medians
are not gains to promote.

Installed preparation took 38.92 seconds of supervised child wall time for all
thirteen sources; checked-attempt preparation took 61.97 seconds, including its
stronger attempt verification, and TypeScript preparation took 9.74 seconds.
These are acquisition observations, not matched compiler-throughput ratios.
Their sampled peak process-tree RSS was 306 / 499 / 156 MiB respectively.
Preparation is paid once per candidate; a narrower selection emits fewer sources.
The final hardened preparation acquired the five-point fast set from three sources
in 13.53 seconds of supervised child wall time. Preparing an existing checked
candidate plus its 16.39-second screen therefore costs about 30 seconds here;
building a new checked compiler is an additional, separate step.

Nine worker scenarios plus receipt-preservation checks pass. Twenty Python controls
pass, covering complete paired runs, wrong results, missing coverage, changed
inputs, bundle path traversal and archive link/duplicate rejection, output preservation, shared
locking, nonzero exits, deadline cleanup including a detached grandchild, SIGTERM
and a deliberately allocating child stopped at its memory limit. The initial
worker-test invocation failed at child creation with sandbox `EPERM`; the same
suite passed in the approved execution context. This was a harness-launch failure,
not a compiler or worker assertion failure, and remains recorded.

Review tightened point/module/worker identity binding, invalidated comparisons
on provenance changes and retained interrupted JSON receipts. After the initial
reference acquisition, preparation was additionally hardened against future
fixture basename collisions, source identity changes and verifier/Node changes.
The original reference keeps the producer it actually used; acquisitions are not
retroactively relabeled as using the hardened producer.

## Interpretation and next use

The presets are maximum wall budgets, not fixed-duration padding. A narrower
selection can finish early. The longer presets broaden coverage and lengthen
warmup/measurement; none proves V8 steady state for every workload. In particular,
historical tree measurements required much longer warmup. Inspect per-sample
ranges, first calls and half-to-half drift before treating small changes as wins.
These protocols differ from historical Phase28–32 runs, so those older medians
must not be used as denominators here.

A case gets a comparison only after every requested role and round succeeds.
Missing or failed samples remain visible. A budget-limited run exits nonzero and
records unexecuted coverage; completed cases retain their own valid comparisons.
A provenance failure invalidates comparisons. Time includes exact output validation,
checksums and the generic-row serializer, so tiny operations include harness cost.

Use the 20-second screen for early rejection, 60 seconds for original-program
transfer, 300 seconds for the broader corpus, and 600 seconds when raytrace is
relevant. Prepare an actual checked candidate once when a manual-JavaScript idea
survives. Correctness gates are still required before admitting an optimization.
The corpus mixes ten existing original programs and five diagnostic points; it
is not a statistical sample of production applications, nor a C/GPU/HVM or
whole-compiler-throughput benchmark. No compiler code or release changed here.

The [protection audit](protected-files.json) confirms all 103 unrelated starting
files remain byte-for-byte unchanged. This phase posts no PR comment.
