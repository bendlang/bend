# Non-tail native array calls

Agent-generated Phase30 investigation. This is a disposable generated-JavaScript
experiment, not a compiler implementation or promotion.

Longer-warm results reject guarding each array read: guards make the row 33.7–43.2%
slower. Bypassing immutable native descriptors improves it only 1.056–1.070× and
does not satisfy the current mutation contract. The semantic and timing evidence
below supports keeping the ordinary array boundary for now.

The [initial prospective plan](../../design/phase30/native-array-call-ablation.md)
proposes replacing descriptor calls with existing runtime array helpers. Independent
review identifies a tail-order counterexample before derivation; the
[prospective amendment](../../design/phase30/native-array-tail-amendment.md) restricts
the experiment to non-tail calls.

## Scope and artifacts

`prototype-array-01` derives six immutable modules from the original checked
Phase29 row fixture and corrected private02: each unchanged context, each with
fixed-native Array.get calls, and each with guarded-native Array.get calls.
The four dynamic Array.get sites per cell change; every `jump` and scheduled
Array.set remains byte-identical. New/size/storage representation are untouched.
The underlying `arrayget` and `arrayset` bodies remain unchanged. Helper-level set
controls exercise the non-tail adapter, but no set call site changes in this row.

The guarded adapter captures the original `get(G,name)` target before evaluating
arguments and validates the actual descriptor after the arguments. It uses the
same guard contract as the direct-leading-lambda experiment: descriptor identity,
ordinary prototype, no `io`/`typeName` override, unchanged code/arity/environment/
bound state, and unchanged code `.call` behavior. A rejected descriptor invokes
the original `call` with the captured target and already-evaluated arguments.
Non-null erased slots conservatively fall back. Public partial entries remain.

The successful direct path still calls `force` on the helper result. This matters
for non-tail Array.set: a foreign returned handle can expose bounce/build properties
and callbacks. Standard host builtin mutation beyond the explicitly guarded
function-call contract is not proved safe by this experiment. The fixed-native
variants intentionally disregard native descriptor replacement/mutation and cannot
be promoted under the guarded ABI contract.

The private context also retains private02's immutable-cell-chain contract;
"guarded" here refers to native array bindings, not a new guarantee for all private
cell callees. No TypeScript ratio is inferred from this within-backend ablation.

## Correctness and rejected tail permission

All28complete four-array Python oracle points pass on all six variants:168finite
observations. A separately implemented differential suite compares original calls
and guarded adapters over44observations: backing-array proxies, handle getters,
throwing accesses, index coercion, ignored erased slot, mutation, returned
bounce/build forcing, native entry replacement, code/arity/environment/bound
mutations and accessors, code-call/prototype changes, actual-row getter behavior
and public partial application. Independent static review is pending; these tests
are not a universal semantic proof.

`prototype-array-tail-witness-01` uses the unchanged runtime's actual `call/apply`
and native `Array.set` to retain the rejected ordering hypothesis. Both paths
finish with storage `[19]` and the same eventual overapplication error. With the
original jump, a copied-vector length observation precedes the array getter;
with eager native execution, the array getter precedes that length observation.
Thus returning an unforced helper result is insufficient to justify eager tail
execution. No tail optimization is present in the derived candidates.

## Mechanism counts

Separate instrumentation over ten32-cell rows verifies:

| Context | Generic applications | Generic calls | Copied slots in apply | Actual array get/set operations |
| --- | ---: | ---: | ---: | ---: |
| Phase29 | 10,930 | 5,770 | 26,330 | 1,280 / 320 |
| Phase29 + fixed or guarded native calls | 9,650 | 4,490 | 22,490 | 1,280 / 320 |
| Private02 | 6,130 | 3,850 | 12,890 | 1,280 / 320 |
| Private02 + fixed or guarded native calls | 4,850 | 2,570 | 9,050 | 1,280 / 320 |

The additional320prebinding and3,840private-projection copied slots in their
respective contexts are unchanged. Descriptor, bound-descriptor, jump, build and
projection counts are unchanged. The guard creates host bookkeeping objects not
counted by these runtime-site counters; these figures are not total allocation
or speed evidence.

Evidence below `selfhost/build/phase30/`: `prototype-array-01`,
`prototype-array-controls-01`, `prototype-array-counters-01`,
`prototype-array-tail-witness-01`, with their raw stdout/stderr and consumed tools.
The first counter acquisition uses CPU6 as explicitly recorded; subsequent
maintained acquisition defaults to CPU5. No counter acquisition is a timing run.

The frozen six-variant `screen.json`/`confirm.json` use the existing row32,seed17
complete-state point and established serial CPU3 protocols. The discriminator is whether
removing the native application boundary matters, and whether per-call descriptor
guards erase that benefit. A closed region could amortize those guards later,
subject to separate admission and semantic evidence.

## Independent boundary review

The independent reviewer subsequently ran 28 additional differential observations
in `selfhost/build/phase30/review-native-array-01/report.json`. All pass. They cover
captured-target replacement during argument evaluation, in-place code changes,
later-call visibility, metadata getter order and errors, backing-array/proxy
mutation, reentrant backing/index callbacks, and `Symbol.toPrimitive` errors.
This supports the frozen non-tail, standard-intrinsic scope.

## Paired timing: reject per-call guards

After independent review, the lead grants exclusive CPU3 access. Other agents
and the lead pause CPU work during the batch; no instrumented counters or
profiling run concurrently. The frozen six-variant screen and longer-warm
confirmation complete with every expected output intact. Exact outputs and all
process/outer-launcher receipts survive in `array-screen-01`, `array-confirm-01`
and their adjacent launcher files.

| Context and array path | Short median ms | Longer-warm median ms |
|---|---:|---:|
| Original cell, generic calls | 0.710980 | 0.279056 |
| Original cell, fixed native bypass | 0.683541 | 0.264223 |
| Original cell, guarded bypass | 0.466842 | 0.372973 |
| Private cell, generic calls | 0.314088 | 0.204119 |
| Private cell, fixed native bypass | 0.305303 | 0.190779 |
| Private cell, guarded bypass | 0.466673 | 0.292280 |

The fixed-native bypass improves the longer-warm medians only 1.056× and 1.070×
in the two contexts. The descriptor guard costs much more than the boundary it
removes: it is 33.7% slower with the original cell and 43.2% slower with private
cells. Both the small fixed gains and guarded losses have disjoint sample ranges.
This rejects per-call descriptor inspection as an optimization for these sites.
The fixed variant is still ineligible for production under live native descriptor
mutation semantics. No type of native bypass is promoted by this experiment.

The short original/fixed samples have severe warmup drift: second halves are
roughly 2.5–3.2× the first halves. The apparent short-window original-cell guard
win reverses after the prescribed longer warmup. Preserve both windows. In the
confirmation, private and private-fixed halves differ by at most 0.98%; private
guarded halves by at most 2.21%. One original sample drifts −6.55% and one original
guarded sample −13.1%; all other long samples are much steadier. These exceptions
remain part of the evidence rather than being trimmed.

The screen costs 11.688s end to end; confirmation costs 126.519s. First-call
medians are original 5.919ms / fixed 5.955ms / guarded 6.756ms and
private 4.903ms / fixed 4.789ms / guarded 5.678ms. Host fixture allocation and complete
state serialization remain included. This is one row kernel, not a production
average or compiler-throughput comparison. A broader closed region might amortize
guards, but that requires separate ownership/effect analysis and evidence.
