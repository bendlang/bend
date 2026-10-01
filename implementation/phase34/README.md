# Phase34: profiles and source comparisons for the current compiler

The compiler is still Phase32 checked03. Its installed API hash matches the
Phase33 frozen reference. [Current results and ranked experiments](opportunities.md)
use the complete unprofiled Phase33 timings and new diagnostics. This phase adds
investigation tools; it implements no compiler optimization and claims no speedup.

The [design](../../design/phase34/program-diagnostics.md) keeps timing and diagnostics
separate. The [diagnostics guide](../../selfhost/tools/performance/programs/DIAGNOSTICS.md)
is the maintained entry point. `run.py --diagnostics all --diagnostic-budget 60`
adds a separate diagnostic budget after successful ordinary timing. `diagnose.py`
can instead consume the exact copied modules from a prior successful run, without
repeating compilation or timing. Existing timing commands retain their protocol.

## New evidence produced automatically

- Raw CPU `.cpuprofile` and V8 sampled-allocation `.heapprofile` files, in separate
  fresh processes after import, a checked first call and explicit warmup.
- Weighted self/inclusive frames, sample counts, GC/harness/unmapped costs,
  reached-depth flags, resource receipts and complete input/tool identities.
  Every generated-program call is checked against its fixed catalog result.
- Real Acorn AST counts, function ranges and source ownership, disjoint source-owned
  top-level summaries, shared tables, normalized tokens, pairwise deltas and an
  escaped standalone side-by-side source viewer. Analyzed code is never imported
  in static mode. Node's embedded Acorn 8.16.0 is required and fingerprinted.
- Function-origin profile locations joined to the smallest containing generated
  AST function and mapped source definitions where available. Runtime/Base code,
  naming-convention inferences and missing mappings remain explicit.

Static sites do not establish execution frequency or allocated bytes. Inclusive
profile costs overlap; only self weights are summed into disjoint owner totals.
Allocation estimates are normalized by completed profiled calls, include observed
harness/inspector allocation, and are neither retained heap nor throughput ratios.
Timing success remains separately visible if a subsequent diagnostic step fails.

## Validation and retained failures

All 28 Python runner/diagnostic controls, 15 analyzer controls and 13 profile
scenarios plus aggregation/preservation controls pass. The eight focused Python
diagnostic tests and all fifteen analyzer controls also pass after final reporting
changes. They cover non-executing static analysis, invalid syntax and HTML escaping,
exact module/point identities, wrong results during first/warm/profile calls,
partial/deadline reports and a diagnostic failure that preserves successful
ordinary timing. CPU/allocation observations and instrumented durations never
enter a throughput ratio.

| Actual run | Coverage | Wall time | Peak profile-worker tree RSS |
|---|---|---:|---:|
| `fast-02`, exact prior three-role timing modules | 30/30 profiles; 15 AST entries | 17.98 s | 80.1 MiB |
| `full-01`, all fifteen points / two roles | 60/60 profiles; 30 AST entries | 244.88 s | 1,221.0 MiB |
| `combined-01`, ordinary pair timing then diagnostics | 1/1 timing point; 4/4 profiles | 2.98 s timing + 5.64 s diagnostics; 8.69 s total | See resource receipts |
| `raytrace-memory-01`, coarser allocation capture | 2/2 profiles; 2 AST entries | 44.40 s | 541.6 MiB |

The full run used a 300-second diagnostic cap. Its AST process peaked at 367.7 MiB;
raytrace's fine allocation sampler caused the much higher profile peak. The
maintained default now samples raytrace allocation every 256 KiB for both roles,
instead of the 32 KiB used elsewhere. The focused control reduced observed peak
RSS to 541.6 MiB and still located the same dominant allocation owners. Both
original and coarser observations remain separate. Limits are polled and can
overshoot; these observations are not a guaranteed maximum on another machine.

Full coverage does not imply uniform profile precision: two near-zero-work
TypeScript profiles reached the ten-million-call cap before their requested
window. Sparse-sample, attribution and allocation-accounting warnings are retained.
All captured calls matched their catalog results. This validates the fixed-input
diagnostic loop; it does not replace broader semantic conformance gates.

The initial analyzer run passed four controls, then exposed a source-map bug:
its export resolver treated a runtime helper as a competing program function.
Restricting that scan to post-runtime program declarations corrected the mapping;
all fifteen controls then passed. Initial and retry logs are retained.

The first real fast diagnostic run completed its AST analysis and five profiles,
then rejected an allocation sample whose node was absent from V8's call tree.
The raw profile contains 7,802 samples; one unrepresented node carries 35,136
estimated bytes. Sample sizes sum to 255,909,216 bytes; tree self sizes sum to
255,891,848. The difference is 17,368 bytes. We do not infer why V8 produced this
shape. The corrected summarizer uses all `samples[].size` estimates, preserves
unattributed samples and separately reports tree totals and disagreements. It
never adds both totals together. The exact discrepancy is a regression control;
the original failure and raw profile remain immutable.

The successful fast retry covers fifteen case/role combinations and thirty
profiles in **17.98 seconds**. It starts from the exact artifacts of the Phase33
three-role fast timing run. Its sampled peak profile-worker tree RSS is
**80.1 MiB**. Warnings about sparse allocation samples, estimated totals or
unattributed nodes remain visible, rather than converting them into fake certainty.

## Interpretation and next work

Use ordinary timing to establish a deficit, then use profiles and source comparison
to choose one mechanism. Current fast profiles point to the private pair's
loop-carried state vector as a cheap next experiment: repeatedly returning a
four-element vector still allocates despite earlier private representation wins.
Larger raytrace/lexer direct-call regions and finite Nat selector tables remain
broader opportunities. [The findings](opportunities.md) distinguish observations,
hypotheses, rejected earlier approaches and the smallest discriminating controls.

A hot helper is not proof that its guard or dispatch instruction caused its whole
sampled cost. V8 inlining and sampling attribution matter; profiler setup/stop
and harness frames can be visible, especially in short windows. These fixed inputs
are not representative production statistics, and no new conformance or compiler
throughput claim follows. Full correctness gates remain separate from this tool.

## Reviewable artifacts

Read [current timings and ranked opportunities](opportunities.md), the generated
[structural report](analysis.md), and download/open the standalone
[side-by-side source comparison](comparison.html). The latter two are exact copies
from `full-01`. The [evidence capsule](evidence/README.md) preserves all raw profiles,
normalized tokens, consumed tools, module copies, receipts and failed attempts.
Its inventory verifies every member after reopening the archive.

Independent review checked lock handoff, separate budgets, immutable timing
snapshots, provenance invalidation and the documentation's interpretation limits.
The [protection audit](protected-files.json) verifies that all 103 unrelated
starting files remain unchanged and unstaged. The installed compiler/API and
upstream pin remain unchanged. No PR comment was posted.
