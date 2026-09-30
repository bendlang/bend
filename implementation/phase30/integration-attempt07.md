# Checked attempt07 integration

The checked attempt07 candidate passes the existing broad backend integration
gates and the inherited primitive and worker runtime controls. The one initial
failure was an obsolete optimization-admission assertion: Phase29 expected an
erased let to enter a private Nat worker, while Phase30's closed scalar region
deliberately refuses erased bindings. A separately frozen two-line adaptation
preserves every runtime assertion and passes. The original failure remains in
the raw evidence.

This is acquisition and correctness evidence, not a performance comparison or
an installation receipt. All commands used CPU4, Node v24.18.0, a 4 MiB stack
and a 1 GiB heap. The parent agent owns eventual installation and release.

## Candidate and provenance

The candidate is `selfhost/build/phase30/attempt-07/attempt.json`:

- Attempt manifest SHA256:
  `7d48caaf1d76cfca59ff069ca052931c18af0ae027887d24698c7039150d2980`.
- Checked API SHA256:
  `035adbea2ab2abbcc9d6b12daf28fecc86d2f85d779d25e24d3d8cf306ffbf99`.
- Runtime SHA256:
  `a3547a8854b45c65fd804f106868dc28540118b611d85fe99ba0e3d199c66ef0`.

The candidate contains owned arguments, scalar regions and literal Nat shifts,
with corrected application-entry scheduling and callable-kind preservation.
The rejected exact-constructor-field extension is absent. See the separate
design, semantic boundary and checked helper reports for those decisions.

The broad runners reuse the maintained suites. For corpus and component/HVM,
`prototype-integration-plan.py` freezes copied launchers with only CPU affinity,
the original tool-root path and Phase30 result labels changed. Exact edits and
hashes are in `integration-launchers-07/plan.json`. Historical tool kind strings
retained by unchanged child suites identify their origin, not the new compiler
version. `prototype-inherited-controls.py` records every checked emission,
consumed tool and historical comparison module by hash.

## Results

All raw paths below are relative to `selfhost/build/phase30/`. Every gate also
has a separate outer launcher receipt retaining command, process result,
complete stdout and stderr.

| Gate | Result | Raw evidence |
| --- | --- | --- |
| Selected upstream JavaScript executions | 15 exact passes | `upstream-js-07/report.json` |
| Maintained generated-library corpus | 23 libraries, 127 complete observations | `corpus-07/report.json` |
| Unedited compiler membership component | 22 independent observations | `component-07/report.json` |
| Whole HVM application | Complete stdout exact; empty stderr | `application-07/report.json` |
| Checked scalar primitives | 56,205 scalar checks, 58 grouped observations | `inherited-primitive-07/report.json` |
| Checked Nat workers | 3,759 scalar checks, 14 complete transcripts | `inherited-worker-07/report.json` |
| Nested Nat refusal regression | 144 checks, 3 refused shapes | `inherited-nested-07/report.json` |
| Synthetic primitive admission and effects | 1,129 guards, 25 observations | `inherited-primitive-guards-07/report.json` |
| Synthetic worker admission and lets | 40 guards, 2 runtime observations | `worker-admission-check-07/report.json` |

The HVM stdout is exactly:

```text
&S{#0{()},#1{()}}
- Itrs: 79 interactions
```

The corpus baseline is the saved **Phase25 corpus**, not Phase29. The checked
primitive and worker controls use the original **pre-worker Phase27** reference
and the pinned TypeScript compiler, with source and checked-output identities
verified before consumption. The upstream pin is
`018751270e800bc222a93dad7f257083ee53a5f7`.

The component/HVM runner also writes an inherited performance configuration.
Its sides are pinned TypeScript, Phase27 and the new Phase30 candidate. That
configuration was **not timed here** and must not be described as a Phase29
comparison.

## Admission assertion amendment

The untouched inherited worker guard suite first stopped after 38 guards at
`yes('erased-let', erased)`. Its receipt is
`inherited-worker-guards-07/report.json`; no runtime observation had executed
when that assertion failed.

The reason is explicit in the frozen attempt07 source:
`j_region_bindings` requires a nonzero binding quantifier, and a failed region
plan makes `j_nat_loop_region` decline the worker. The erased-let program still
uses the generic compiler path. Supporting an optimization is separate from
preserving program behavior.

`prototype-worker-admission-adapt.py` derives a fresh suite from the retained
failed run's exact frontier suite. Its prospective plan changes only:

1. Expected erased-let optimization admission from accepted to declined.
2. Expected emitted private Nat worker markers from two to one.

All 40 guard cases remain. Both executable let assertions remain byte-for-byte:
the erased RHS must never run, with result `107` for 100 iterations from `7`;
parallel RHS evaluation must see the old binding, with result `7`.
The adapted suite passes both. The accepted parallel-shadow worker continues
to exercise the optimized path; the erased case exercises its generic fallback.

The adaptation, hashes and complete child outputs are under
`worker-admission-plan-07`, `worker-admission-plan-07-outer`,
`worker-admission-check-07` and `worker-admission-check-07-outer`.

## Scope and iteration cost

Descriptive outer launcher costs were approximately 40.50 s for the 15 upstream
executions, 114.75 s for the corpus, 13.64 s for component plus HVM, and
20.45 s for the four inherited primitive/worker/nested/primitive-guard gates.
The final amended worker checks took 0.32 s; the retained initial admission
failure took 0.77 s. These acquisitions were not isolated comparative timings.

Frontend source was unchanged, so this bounded batch did not repeat the full
frontend suite. These passes establish the maintained selected integration
surface, not universal backend conformance. Foreign getter order, mutable
global descriptors and callable-kind behavior also need the independent
Phase30 boundary suites already tracked separately.
