# Phase33 current frontier

User authorization covers compiler research, experiments, implementation,
design/report and commit/push to `rom1504/bend`, branch `selfhost/bootstrap`.
No PR comments without an explicit request. Prior timed campaigns are historical.
[Design](../design/phase32/representation-and-reuse.md),
[report](../implementation/phase32/README.md),
[selection and accepted costs](../design/phase32/admission.md).
All four investigations, integration, ordinary/relocated CLI checks and evidence
preservation are complete. The 103 unrelated starting files remain byte-for-byte
unchanged and unstaged; preserve that separation in later work.

## Generated-program loop consolidation

The user prioritizes a reusable execution loop before more optimization.
[Phase33 design](../design/phase33/program-execution-loop.md) and
[report](../implementation/phase33/README.md) consolidate the existing points into
[one maintained runner](../selfhost/tools/performance/programs/README.md).
Use 20 / 60 / 300 / 600-second ceilings with independent sets or explicit cases;
prepare checked candidate modules separately and reuse them. Frozen references
run from a normal clone. Default sets contain 5 / 8 / 14 / 15 points.
Short timings are rejection screens; unchanged-compiler noise and JIT drift are
visible. No historical median is used as a new comparison denominator. Compiler
throughput and conformance remain separate. Phase32 checked03 remains installed.

## Installed Phase32 compiler

Target remains upstream 0187512, after Bend 2.0.34. Phase32 checked03 is installed
and release verification passes. All 14 pre-install gate groups pass and 223
canonical source identities match. All 42 ordinary/relocated CLI controls pass.
[Current release](../implementation/phase32/release-03.md),
[baseline release](../implementation/phase31/release-07.md).

Installed API `8be506d8…`, genuine checked parent `c3cc54c1…`, assembled source
`e3cc4424…`. Runtime `4121f338…` and Base `c742fae9…` are unchanged. The selected
API remains a maintained guarded version 6 derivative of its checked parent;
no new self-emitted H image or fixed point is claimed.

Three transformations reuse the existing bounded closed-region proof:
return-position unpacking becomes lexical statements; typed bridges fuse
canonical Array<U32> reads with immediate private consumers; eligible private
records/Sigma use field vectors. Producer-time reads, ordered fields and initial
zero rebinding stay observable. Public terminal-record results remain boxed.
Runtime, driver, public representation and unsupported fallback are unchanged.

## Measured results and costs

[Final measurements](../implementation/phase32/final-measurements/measurements.md):
original four-pair edit distance 72.266→20.398ms, pinned TypeScript 4.988ms.
**3.54× faster than 07; same-window gap 14.49×→4.09×TS.** Mandelbrot and RLE
emit identical 07 bytes with overlapping timing ranges. Their candidate/TS
ratios are 4.46×/76.22× in this window; other seven originals lack fresh timing.
These selected programs do not establish typical or average generated speed.

Checked01→02→03 isolates statements, typed read bridges and vectors. Longer
confirmation gives pair 18.535→4.925ms (3.76×, still 3.78×TS), fold 0.651→0.329ms
(1.98×, still 8.13×TS). Every adjacent increment has disjoint improvement ranges.
The last increment includes canonical Sigma construction; the fold changes no
ordinary record shell. One candidate fold sample warms 27% between halves.
Preserve raw samples and do not claim steady state.

Mandelbrot library compilation adds 36.75ms/+1.91% with disjoint ranges;
edit-distance −0.45% overlaps. Candidate request-only gaps remain 5.56×/4.90×TS.
All three scalar/generic regression canaries overlap. Admission explicitly
accepts the compilation cost, +0.39% Mandelbrot peak-RSS median and source/
generated-size costs. No compiler-throughput improvement is claimed.

Source: 17,071 physical /14,580 nonblank Bend lines; 1,884 definitions, 640 laws,
70 types,66 modules. Net +57 physical lines (+0.335%),+51 nonblank,+6 functions,
+2 private plan tags. No new type/module. Pair/fold generated modules grow
4.21%/1.08%, mainly bridges. This is a representation improvement with a small
source increase, not progress toward the historical 50%/75% line-reduction goals.

## Rejected and deferred alternatives

- [Private checker fields](../implementation/phase32/checker-private-fields.md)
  improve selected H17 helpers 1.44–1.76× in matched experiments. Public getter
  and mutation witnesses prevent promotion without an actual ownership boundary.
  H17 is a historical generated compiler, not B1 or handwritten TypeScript.
- [Semantic checkpoints](../implementation/phase32/reuse-counts.md) preserve 22
  observations and skip 484–508 events, but equality/freezing/retention is too
  costly for normal requests. Reject full-world retention; this does not reject
  a genuinely private immutable Base design.
- [Compact memoization](../implementation/phase32/compact-counts.md) finds repeat
  queries, but global wrappers and scoped 4k/16k tables fail the prospective
  speed criterion. A new compact IR is not justified by these measurements.
- [Stop-list reuse](../implementation/phase32/compact-stop-reuse.md) finds duplicate
  driver work. A shared mutable default API defeats `api == null` as an ownership
  proof; concrete witnesses preserve changed second-call behavior. Driver stays
  unchanged. A private source-only worker is a future hypothesis.

## Integration and bounded execution

The selected candidate passes 36 focused checks and six added control groups:
complete pair states / 328,966 native events, fold oracles, actual read ordering,
lexical scopes, public boxed records/aliases and compiled layout predicates.
[Independent controls](../implementation/phase32/review-vector03.md).
Fresh 3,026 main + 196 broader frontend observations agree with the rehashed frozen
pinned reference. The interrupted broader receipt is preserved beside its fresh
successful retry. Backend 81 retains 69 pass /8 N/A /4 shared failures through 60
unaffected rows plus 21 approved-context native retries. The original 17 paired
Clang EPERM failures remain preserved. Fresh primitive 56,205, worker 3,759,
nested 144, primitive guards 1,129, selected upstream 15, libraries 23 / 127 points,
worker admission 40 + 2, components 22 and complete HVM 42-byte output pass their
overlapping scopes. [Gate closure](../implementation/phase32/final-conformance/gates.md).
All 42 ordinary/relocated CLI controls pass in the approved native execution
context, taking 42.19 seconds with about 577 MiB peak process-tree RSS.
No full backend, GPU or proof-kernel conformance claim is authorized by these tests.

Only root runs heavy work. Use one worker, explicit Node heaps, the shared
execution lock, process-tree RSS/deadline supervision and 2 GiB available-memory
floor. Checked builds take about 40 seconds with a 1 GiB heap setting. Polling can
overshoot the RSS limit. [Supervisor controls](../implementation/phase32/supervisor-controls.md)
verify termination/child cleanup; resource counters do not establish the cause
of prior session interruptions. Never rerun a completed gate just after restart.

The verified [evidence capsule](../implementation/phase32/evidence/README.md)
preserves 20,807 files / 207,091,523 logical bytes in a 33,930,135-byte gzip,
including failed/superseded attempts and frozen tools. All producers were closed
before capture; reopened member hashes, sizes and modes match the inventory.
The [final protection audit](../implementation/phase32/protected-files-final.json)
finds all 103 starting files unchanged, and the previous Phase31 release's seven
history files match their pre-install identities. Keep exact staged paths separate
from protected files; do not run benchmarks concurrently with archive work.

## Next decisions after release

1. Start new measurements from admitted 03, retaining its accepted costs. Inspect
   remaining read/vector/allocation work on the saved checked pair and fold;
   require a discriminating boundary control before another checked build.
2. For compiler throughput, test an explicitly private source-only worker
   boundary before reusing stop lists or direct fields. Public API mutability
   is a demonstrated counterexample, not a hypothetical future issue.
3. Keep generated execution, ordinary library compilation and actual self-emitted
   H throughput separate. Do not multiply historical gains from different windows.
4. Require broader program transfer before inferring a general win. Keep mixed
   generic/specialized canaries: Phase31's registration costs remain in 03's baseline.
5. Do not start a large rewrite or new ownership system on count evidence alone.
   Short saved-output controls, bounded screens, checked acquisition and selected
   transfer precede another expensive full frontend/backend integration.
