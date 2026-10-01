# Phase36: reduce repeated proof work and private producer dispatch

Starting release: Phase35 checked09, commit88619d9, API
`467bc7dec2751a94cb677c5eb2da22a8fb69ee3522c6e164cb2bfcc147a78d82`.
Upstream stays pinned to018751270e800bc222a93dad7f257083ee53a5f7.
This campaign continues generated-program optimization with correctness,
compilation latency, source complexity and output size reported separately.
[Prior profiles](../../implementation/phase35/profile-findings.md) and
[compiler costs](../../implementation/phase35/compiler-cost.md) define its starting evidence.
This prospective plan is frozen before timing; outcomes belong in implementation reports.

## Hypotheses and decision order

1. **Scoped guard proof.** Ray's repeated guard work accounts for47.24% of sampled
   CPU ancestry. Its outer pure region already checks most nested dependencies.
   A proof valid only within that synchronous invocation may discharge redundant
   nested guards. Establish complete coverage, exact-entry/canonical-input checks,
   no user-code invalidation and finally restoration before measuring. A global
   across-call cache is outside the proposal. Reject on callback/reentry, mutation,
   partial/raw entry, exception, oversaturation or delayed-field counterexamples.
2. **Private tree producer.** Symreg's generator now accounts for64.33% of sampled
   CPU ancestry. Test a small scalar-input Nat-recursive producer subset with
   ordered child construction, original tagged data and explicit frames. Do not
   specialize source names, benchmark constants or input sizes. Public fallbacks,
   complete trees, sharing, demand order and depth remain observable controls.
3. **Skip provably unproductive analysis.** Look for small exact-output compiler
   changes, initially avoiding vector inlining traversal when no vector-returning
   helper can qualify. Source simplification and byte-identical output are preferred
   to introducing broad caches or a new intermediate representation.

The prior literature study supplies worker/wrapper, scalar-replacement and bounded
known-value analysis precedents. It does not discharge these local host/runtime
proof obligations. Start with code, saved-output ablations and finite counterexamples;
only a surviving mechanism gets a checked compiler implementation.

## Baseline and measurement protocol

The incremental baseline is **Phase35 checked09**, not Phase32. Reuse its exact
checked fifteen-point prepared modules and checked emission receipts, relabeling
only their comparison role through a recorded adapter. Retain pinned TypeScript
modules from the unchanged portable reference. Verify catalog, source, input,
module, compiler and preparation identities. Preserve the original artifacts.
No new compiler execution is implied by this metadata adapter.

Use the maintained program suite and unchanged input catalog. Cheap screens use
20/60-second ceilings; surviving changes receive300/600-second confirmations and
original-program transfer. Preserve balanced fresh-process rotations, CPU3, Node
24.18.0, exact full results and raw samples. Prefer improvements above5% with
disjoint observed ranges; investigate disjoint regressions above3% and material
apparent regressions even with overlap. No benchmark average or steady-state
claim follows from a few selected inputs. Missing/failed points remain incomplete.

Saved-output experiments are explicitly unchecked mechanism evidence. Bind their
consumed input and producer bytes; keep diagnostic counters out of clean timing.
Every accepted mechanism must also appear in checked compiler output with an
actual-entry witness. Profiles and AST/static comparisons run separately.

Measure normal checked-library requests on unchanged pair, Mandelbrot, symreg
and ray sources with each compiler's validated Base pipeline, independently checked
expected output and three rotated fresh processes. Reuse the maintained worker
semantics; separate imports, request, verification/process wall, RSS and bytes.
Slower compilation is admissible only as a recorded tradeoff; it cannot be hidden
inside a runtime gain. Report physical/nonblank source, definitions, types/modules,
and generated output growth against this phase's actual baseline.

## Correctness, consolidation and resource limits

Root alone runs builds, tests, timing, profiles and archive capture. Agents inspect,
research, propose patches and independently challenge proofs. One heavy child tree
at a time, CPU3, one compiler worker, explicit Node heaps at most1024MiB, outer
process-tree RSS cap at most2048MiB, a2048MiB available-memory floor and bounded
deadlines. Shared execution lock, serial jobs and fresh output directories remain.
Never alter the closed Phase35 raw tree or the103 protected starting files.

Each source candidate uses the maintained checked B1 workflow plus strict Focus36.
Run affected owner controls first, retaining complete storage/ordering oracles and
new proof-specific refusal/admission/host controls. Final combined promotion needs
all applicable Phase35 owners, inherited execution/library/component/HVM controls,
3,026+196 exact frontend observations and81 preserved backend observations using
the existing assertion bodies, plus exact canonical-source equality. Counts overlap;
shared failures and unavailable backends retain their verdicts. No GPU, full backend,
independent proof-kernel or self-emitted fixed-point claim follows.

After separate performance/cost admission: install the selected image, verify it,
run all42 ordinary/relocated CLI checks, audit final identities and preserve the
complete raw campaign including failures. Update current docs/report/ledger,
commit and push within the user's authorization. No PR comment is authorized.
