# Fresh argument vectors: first checked implementation

Agent-generated Phase30 progress report. This is a checked development candidate;
Phase29 remains the installed release until final integration and review.

## Mechanism and measured prototype

An emitted non-tail call creates a fresh argument array. Generic `apply` used to
copy it immediately even when no partial prefix existed. The prototype consumes
that private array, retaining public-call copies, bound-prefix concatenation,
oversaturation slices, matcher field-vector copies and every tail-message copy.
The [prospective design](../../design/phase30/owned-arguments.md) freezes this
ownership boundary separately from private workers and loops.

On the existing Mandelbrot helper point128/524800, the frozen short screen gives
0.425999ms old versus0.370800ms owned (1.149×). One candidate half drifts strongly;
the predeclared longer-warm confirmation uses the same bytes and inputs:

| Output | Median ms/call | Five-sample range ms |
| --- | ---: | ---: |
| Phase29 | 0.399032 | 0.395993–0.435573 |
| Owned prototype | 0.351041 | 0.348365–0.362086 |
| Pinned TypeScript | 0.00170137 | See raw samples |

This is1.1367× faster, about12.0% less elapsed time on this fixture. All candidate
half ratios are within2.7% of1 and old halves within8.6%. Ranges do not overlap;
five samples do not establish confidence bounds or universal steady state.
First-call medians are6.318ms old and6.180ms candidate. The remaining gap is about
206× TS on this specific helper input. This is generated-program execution,
not compiler throughput or a representative production average.

The short/long launchers cost6.628s/63.626s end to end. Both protocols use serial
rotated fresh CPU3 processes, Node24.18.0,4MiB stack,1GiB heap, input identity
checks and complete expected outputs inside every call. Instrumentation is
excluded. Raw evidence is `selfhost/build/phase30/owned-{screen,confirm}-01` and
adjacent launcher receipts; `owned-01` contains the derivation, oracles and
frozen configs. The derivation tokenizer was tightened to refuse member `.call`
syntax after review; a separate audit proves every27retained01sites was already
a bare runtime call, so its original bytes and result remain valid.

## Actual compiler change

`emit.bend` changes two non-tail emission branches from `call` to `callOwned`.
Both construct a literal argument vector. `core.mjs` gives `apply` an explicit
ownership flag and adds the internal wrapper; `call` and `jump` retain their
public behavior. The runtime bundle is regenerated from its source fragments.
No new Bend lines, IR, calling representation or recognition pass is required.
The core runtime gains three physical lines and modifies two existing lines.

Checked attempt01 has API
`4bd4d11012ee61573589d8bd7f060b20e2c7a70d3062c35108b5342174cbb08e`
and runtime
`b62b509094ebbf726e3c287dc2b7b65d1d1de9977065903b1de3f4c588d3e804`.
Its36focused exact observations pass. Emitting the existing fixture takes4.775s
including lineage verification; its120independent points pass in0.165s. These
acquisition costs occurred alongside other work and are descriptive only.

The compiler-produced program suffix is byte-identical to the prototype suffix,
including27owned call sites. Runtime helper placement/comments differ, so the
prototype timing is not silently relabeled as an actual-compiler timing; that
fresh comparison and broader transfer remain integration work.

## Independent validation and limits

`review-owned-emitter-01` tests actual `j_library` output from the frozen checked
candidate and Phase29 using their matching runtimes. It passes22observations:
one/batched/partial/erased/ordered calls, metadata getters, mutated received
arrays, partial ownership, overapplication, null/type/env behavior, public array
isolation and reusable tail messages. It confirms five selected owned sites and
the unchanged tail jump. Synthetic core controls test the emitter/runtime;
frontend admission is covered separately by the checked36case gate.

The existing runtime application suite also passes. The initial prototype's
120point scalar oracle and11paired runtime observations are separately retained.
These overlapping observations are not a unique conformance total. No compiler
release, broad conformance, self-hosted fixed point or native/device speed claim
follows from this checkpoint. Installation follows final integration.
