# Reproduce the broader program comparison

The [design](../../design/phase28/broader-program-comparison.md) was committed
before acquisition. The [report](broader-program-comparison.md) gives per-program
results; [workloads](workloads.md) and [applications](applications.md) define
the actual work and oracle boundaries. No compiler source changes are involved.

## Inputs and compilers

Commands start at repository root with Node24.18.0. The Python launchers use
`PHASE25_NODE` where supported; the application config records its exact Node
path. Pin018751270e800bc222a93dad7f257083ee53a5f7 is the TypeScript compiler and
source baseline. The sparse reference checkout omits some demos/benchmarks;
their original source blobs are available through `git show PIN:path`.

Six algorithm fixtures preserve those bytes as exact prefixes and append a
small pure entry point. Four mixed tests and the HVM application are unchanged
pinned files. All live in `selfhost/tools/performance/phase28/corpus/` with
manifests. Original `main` remains in the algorithm libraries; it is not called
with its enormous default input. Benchmark wrappers use documented small inputs.

The selfhost side is the verified immutable Phase27 attempt02, matching installed
API5a89c775 and runtime40823818. Recover it from the
[Phase27 capsule](../phase27/evidence/README.md), or build a new checked attempt
from the identical canonical source using the maintained development workflow.
Record new identities rather than pretending relocated historical paths renew
the original acquisition. The installed release verifies separately with:

```sh
node selfhost/tools/development/release.mjs --verify
```

## Acquisition

The acquisition launchers document their arguments in source and record complete
commands and consumed identities. They use120s compile and60s first-execution
deadlines,4MiB stack,1GiB heap, CPU4 for algorithms and CPU6 for applications.
Acquisition can run concurrently; its durations are not clean comparisons.

The underlying checked library emitters are:

```sh
node --stack-size=4096 --max-old-space-size=1024 \
  selfhost/tools/performance/phase25/emit.mjs upstream INPUT.bend OUTPUT.mjs
node --stack-size=4096 --max-old-space-size=1024 \
  selfhost/tools/performance/phase26/emit.mjs ATTEMPT INPUT.bend OUTPUT.mjs
```

Every module receives a receipt binding its source and output. The immutable
attempt emitter additionally checks API/runtime/Base/driver lineage. Upstream
pin, clean checkout and consumed source identities are bound by `prepare.py`.

The final raytrace wrapper is `raytrace-typed.bend`. The original and annotated
wrappers are preserved failures, not supported alternative inputs. They kept
the original algorithm and parameters but used uninferable local Nat syntax.
Likewise, the upstream HVM program requires a `.cjs` host; the failed `.mjs`
launch is retained. Successful retry changes its extension, not emitted bytes.

## Clean measurement

Stop all other compilations, generated-program executions and diagnostics. The
preserved `timing-config.json` lists ten library pairs, complete expected scalar
or string values, export names and argument arrays. `library-provenance.json`
ties those inputs to checked emission receipts. `prepare.py` reproduces that
selection from the acquisition metadata at its recorded paths.

```sh
python3 selfhost/tools/performance/phase28/measure.py CONFIG.json NEW_TIMING
python3 selfhost/tools/performance/phase28/measure-application.py \
  APPLICATION_CONFIG.json NEW_APPLICATION_TIMING
```

Run these serially. After both original campaigns finish, the
[prospectively recorded follow-up](../../design/phase28/warmup-followup.md)
repeats all four cases with repeated greater-than10% within-block drift:

```sh
python3 selfhost/tools/performance/phase28/measure-long.py \
  LONG_CONFIG.json NEW_LONG_TIMING
```

Its config selects Mandelbrot, tree-bitonic, morning and Map/Set from the same
immutable pairs. It derives and records a runner with at least100 calls AND
3000ms warmup. All other comparison operations remain; keep both windows.

The original library harness uses CPU3, Node24,4MiB stack,1GiB heap,
and five fresh processes per side in alternating order. Each process records
import and first useful call separately, then warms for at least three further
calls and1000ms. Separate calibration targets300ms, with fixed per-side repeat
counts and a1M-call cap. Exact result checks remain inside timed calls. Record
actual durations: a single expensive call may exceed the target substantially.
Timed halves expose possible within-sample drift when repetitions exceed one.

The application harness times five whole fresh processes per side, from spawn
through Node startup, program load, computation, output and exit. Both receive
identical CPU/stack/heap limits and sanitized environment. It checks the entire
stdout and empty stderr. The normal form is supported by the source commentary;
the interaction count79 is a differential agreement, not an independent proof.

Every failed process is retained. First-call, warmed-library and complete-process
ratios are distinct metrics; do not pool them. Tiny test inputs are not scaled
applications, and a broader algorithm suite is not a production workload survey.

## Evidence

The [capsule](evidence/README.md) preserves emitted bytes, source/tool copies,
all acquisition attempts, raw process logs, configs, checks and measurements.
It verifies every archived byte independently. The
[measurement audit](measurement-audit.md) separately checks raw results,
identities, ordering, timing arithmetic and claim scope.

## Replay the independent audit without running programs

The preserved [window auditor](measurement-audit.py) and
[report assembler](measurement-audit-assemble.py) use Python 3.9+ and Git, with
no third-party Python dependencies. They read and hash evidence, run `git show`
to verify source blobs, and recompute statistics; they do not execute Node,
generated programs or compiler builds.

These exact historical scripts hardcode
`/home/ai/bend2/build/publish/bend` and retain absolute paths from the receipts.
Replay requires the Phase28 capsule, Phase27 attempt02 prerequisites, pinned
upstream checkout/Git objects, consumed source/tools/release files and the exact
recorded Node binary at those paths. The Node binary is hashed only. Recover
these identities before auditing; relocating files alone does not satisfy the
historical identity checks. Use an isolated recovered workspace: the assembler
**overwrites `measurement-audit.json` and `measurement-audit.md`**, including
their audit timestamp. It leaves the closed build capsule unchanged.

From the recovered repository root:

```sh
cp implementation/phase28/measurement-audit.py /tmp/audit-phase28.py
python3 /tmp/audit-phase28.py --final
python3 /tmp/audit-phase28.py --long --final
python3 implementation/phase28/measurement-audit-assemble.py
```

The first two invocations write separate temporary audit JSON files. The exact
copy at `/tmp/audit-phase28.py` is also required because the assembler hashes
that historical script path. Both window audits must report `PASS` before
assembly. A replay renews the audit of saved observations, not the measurements.
