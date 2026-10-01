# Scoped guard proof investigation

Root's first saved-output colf control run passes 57 oracle rows and 200 boundary
observations (`selfhost/build/phase36/guard-controls01`). Scope controls then
reject a vacuous `nearest.t` replacement witness: the chosen ray never called
that helper. Original and candidate observations agreed, but agreement without
hook execution cannot validate that boundary. The failure remains at
`guard-scope01`; v2 uses a center pixel that is expected to hit a sphere and must
actually execute the hook. The later mechanism evidence below supersedes the pending timing status; no
production promotion follows from these observations. No production source has
been modified by this owner.

Static inspection finds `rowf` and `colf` have complete existing guard lists for
their transitive independently pure residual call graph. Both accept only
canonical native scalar inputs. Nested `nearest`/`nearest.t` retain their own
11-name checks even under that complete outer proof. The opportunity is proof
reuse inside the dynamic extent, not removing mutation guards from public calls.

The [design](../../design/phase36/guard-scoped-proof.md) records proof obligations,
falsification criteria and planned mutation/demand controls. Saved-output and
checked-compiler evidence will be linked separately here after root executes it.

## Error callback found in static review

Guard owner and producer owner independently identified a missing boundary:
native `Succ` overflow calls `checkedNat`/`bad`, which calls mutable global `Error` while the
first prototype's proof was active. Its callback could mutate a private helper
and reenter a covered root before unwinding. The v1 proposal is therefore not
promotable even though the original ray controls pass.

`guard-derive-v2.mjs` and `guard-production-v2.patch` suspend proof through error
construction in `bad`, restoring only during exception unwind. This avoids
assuming that checking global Error identity also excludes callbacks through
Error's mutable properties. Actual compiled-source controls are provided by
`guard-overflow-v2.bend`, `guard-acquire-v2.py` and `guard-overflow-controls-v2.mjs`.
The candidate must visibly enter its tree proof on benign calls; overflow's
Error callback must run with inactive proof, replace a directly lowered helper,
and reenter with the changed result. All four error modes compare complete
result/error/event observations against the checked baseline. Not yet run.

## Whole-root purity required

Independent cost review found v2 admission incomplete: scalar inputs plus one
pure residual do not exclude a different directly lowered helper from calling
native Array.new. Its fill/isSafeInteger host hooks can invoke callbacks while
the proof is active. v3 requires the complete original root to pass JPure, which
rejects all native arrays, IO, functions, foreign calls and unsupported native
operations. A bounded duplicate proof costs additional compilation work but is
necessary; ray has about 28 reachable definitions, within the 32-definition cap.
The actual compiler must establish admission rather than relying on that count.

`guard-array-refusal.bend` and `guard-array-controls.mjs` demand both properties:
the old private tree remains, but no proof scope is emitted. The callback tests
replace Array.prototype.fill/Number.isSafeInteger, mutate a private helper and
reenter, or throw, comparing all result/error/event observations. The source
fixture and controls have not yet been run. No production changes by this owner.

## Callback-surface audit for v3

- Source scalar operations use the explicit j_primitive whitelist: native
  U32/F32 arithmetic and U32↔Nat conversions. Math, Number and BigInt identities
  used by those operations are covered by the existing host snapshot.
- The only residual native admitted by JPure is F32.to_u32; its finite/truncation
  hooks are already in that snapshot. Native Nat.add/mul, F32.bits/show/read,
  strings, collections, IO and foreign code are refused.
- Primitive F32/U32 constructor pattern projection would expose Word(32), whose
  parameterized/dependent type fails JPure. It cannot reach mutable DataView
  conversion methods through an admitted root.
- Nat constructors can invoke checkedNat/bad; v2's explicit error boundary
  suspends proof through mutable Error construction and its host properties.
  JPure admits no source/runtime catch that can resume inside the old proof.
- Generic dispatch touches only compiler-owned captured wrappers, fresh argument
  vectors and locally created tagged values. Its function/array protocols and
  marker prototype hooks are covered by the preexisting exact and host guards.
- Tree frames and proof dictionaries use own data fields/counting loops. The
  private dictionary has null prototype and uses no unguarded Set/Map methods.

This audit narrows the proof argument; it is not a substitute for checked-source
admission/refusal/error controls or the inherited descriptor/mutation gates.

## Saved-output mechanism outcome

Root completed `guard-derived02`, `guard-controls02`, `guard-scope02` and
`guard-screen02`. All 57 colf oracle rows, 200 existing mutation/demand boundaries
and 10 new scope observations pass. On the three live colf points, each public
root performs one full host check and reuses 8, 16 and 8 nested checks respectively;
every extent is closed before return. Scope controls include actual post-success
helper replacement, and diagnostic-only throw, deferred bounce/build and covered
versus uncovered-name exits. Those synthetic cleanup checks are explicitly
separate from the pending real compiled-source overflow and array-refusal tests.

The clean, unprofiled original ray workload uses five balanced fresh-process
rounds on CPU3 with the maintained worker. All exact outputs pass:

| Variant | Median ms | Range ms |
|---|---:|---:|
| Phase35 baseline | 1868.350 | 1863.724–1874.943 |
| Scoped-proof saved output | 792.226 | 790.040–802.958 |
| Pinned TypeScript | 34.212 | 34.028–34.757 |

This is **2.358× faster than Phase35**, still **23.157× slower than TypeScript**.
The whole experiment completes in 96.502 seconds. Timing does not use diagnostic
counter modules. The clean candidate is 130,214 bytes versus the original frozen
129,177 bytes. These are generated-output ablation results, not yet measured
results from the changed compiler. Root has applied production v3 plus the
independent producer proposal and started checked02; actual compiler admission,
controls, compilation cost and broad outcomes remain pending.

The earlier 1.9× figure was an illustrative Amdahl estimate holding non-guard work
constant based on one instrumented CPU sample. The observed 2.358× gain exceeds
that simplified model; it does not identify which JIT/allocation interactions
explain the difference. Use clean timing for speed and profiles for localization,
not a sampled ancestry fraction as a universal speed limit.

The checked-output adapter `guard-checked-controls-derive.mjs` verifies complete
emission receipts, actual API/runtime/Base/driver identities, the frozen whole-root
purity gate, and actual rowf/colf scope bodies. It adds counters/exports only and
copies the clean compiler output byte-identically. Its colf assertion adapter
retains the same 57/200 controls; its copied scope-v2 script is byte-identical.

## Checked compiler evidence: checked02

Root's checked02 API is
`039df711cdb4cdf0d8bb5f37f785104913975e890fe02b8286683f99d283fdb3`.
The real compiler's ray module passes the same **57 oracle rows / 200 colf
boundaries**, plus **10 scope observations**, through the diagnostic-only checked
adapter (`guard-checked02`, `guard-checked-controls02`, `guard-checked-scope02`).
The full independent root proof actually admits both rowf and colf; the adapter
verifies that gate in the frozen checked source and requires the real emitted
scope/cleanup structure before adding counters.

Actual `guard-overflow-v2.bend` passes **16 benign oracle rows and four error
boundary modes** (`cohorts02-retry/overflow-v2`, `guard-error02`). The candidate
really enters its scope on benign calls. Native Succ overflow's Error callback
sees inactive proof, replaces guard.direct, reenters with the expected changed
result 44, and leaves inactive proof after both normal and replacement-constructor
throws. Error.stackTraceLimit getter behavior matches the checked baseline too.
The initial acquisition's sandbox TypeScript EPERM remains in `cohorts02`; root's
approved serial retry succeeds without changing assertions.

The original array-refusal source fails baseline parsing because a computed
Array.get result was destructured directly; it is not a semantic observation.
`guard-array-refusal-v2.bend` adds a separate helper matching a named pair
parameter. `guard-acquire-v3.py` and `guard-array-controls-v2.mjs` reference that
successor, retaining the original scope-refusal and callback assertions. Its
actual result is pending. No broad conformance or final promotion is claimed
from checked02's focused results.

## Selected compiler focused guard closure: checked03

Selected checked03 API is
`93e55ad7ee456eebb5fa3dd9606c2cf262ea386c6f66bfd891ffe187d8f50a75`.
All guard owner controls have now passed on its actual compiler output:

| Gate | Observations | Raw report |
|---|---:|---|
| Checked ray colf | 57 oracle rows / 200 boundaries | guard-checked-controls03 |
| Checked ray proof scope | 10 observations | guard-checked-scope03 |
| Actual Succ overflow/Error reentry | 16 oracle rows / four boundaries | guard-error03 |
| Mixed native-array proof refusal | 16 oracle rows / four boundaries | guard-array03 |

The successful array-refusal-v2 fixture keeps its existing private tree but emits
no proof grant. Its fill and isSafeInteger hooks execute with inactive proof;
fill can replace guard.mix and reenter with result 37, or throw the same sentinel
error as the baseline. This closes the full-root purity counterexample identified
by independent review. Original parser failure and superseded fixture remain.

`guard-checked03/derive.json` binds ray's diagnostic-only counters to verified
checked03 source/API/runtime/Base/driver receipts. `cohorts03` binds the actual
source fixtures. All named results here are focused owner evidence; final broad
integration, unchanged maintained timing, installation and release claims belong
to the parent phase report.

A follow-on runtime reflection experiment also passed its named semantic controls
but showed no reliable speed gain (792.012→793.867ms). It was rejected, with no
production change. See [the separate null-result report](guard-exact-report.md).
Further micro-check removal is not justified by this evidence.
