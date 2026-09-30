# Final candidate14 selected integration

The final maintained candidate is checked **attempt14**. It passes a fresh
complete rerun of the selected integration gates below. Candidate12's earlier
acquisition remains recorded separately later in this file and is not relabeled
as candidate14 evidence. The guard fixed-list and general tail-Let experiments
were deferred; their generated-JS prototypes are not part of this image.

| Final artifact | SHA-256 |
| --- | --- |
| Attempt14 manifest | `e2f95d0525f765bfb1221d81aa5ba6962d67f627c9abd048a494b31b65d96daa` |
| Checked bootstrap parent | `cb2a5555e8ad6afc51e3bc778242e26334f11c40b720028650b8b4c0525f2deb` |
| Selected equality-derived API | `ade96ba48b05ba116430f57e433d8fbdbd76646b61f5e9d53cf34a4c4a9da76d` |
| Frozen runtime | `a3547a8854b45c65fd804f106868dc28540118b611d85fe99ba0e3d199c66ef0` |
| Pinned Base | `c742fae9c49b14f0cc9128429a2c6109364c8a933a142f2c90b9f2e5fd976661` |

Fresh receipts are under `selfhost/build/phase30/final-integration-plan-14/`.
Both `gate-launch-cpu4/report.json` and `gate-launch-cpu7/report.json` are
complete and pass. The root owns CPU4's selected-upstream acquisition; the
independent reviewer executed the seven serial CPU7 commands through the
unchanged frozen launcher. Every consumed plan identity was reverified after
the run. The frozen plan hash is
`0aedae42096681773d0c43980f8cada851b9ca40b2ffffc9a6492aec3fd31fa2`.

| Fresh final14 gate | Result | Receipt directory |
| --- | --- | --- |
| Selected upstream JS execution | 15/15 pass on both sides; zero exact differences | `upstream` |
| Scalar primitive oracle | 56,205 scalar checks; all58 observation rows pass | `primitive/comparison` |
| Native worker oracle | 3,759 scalar checks and14 additional observation rows pass | `worker/comparison` |
| Nested-worker oracle | 144 checks pass | `nested/comparison` |
| Primitive admission/refusal | 1,129 guards and25 execution observations pass | `primitive-guards/comparison` |
| Worker admission/refusal | 40 guards and2 execution observations pass | `worker-admission` |
| Checked library corpus | 23 libraries,127 complete points pass | `corpus` |
| Real compiler membership component | 22 complete observations pass | `component` |
| Whole HVM5 program | Exact complete stdout; empty stderr | `hvm` |

The final HVM output remains exactly:

```text
&S{#0{()},#1{()}}
- Itrs: 79 interactions
```

Only compiler-image bindings and the already frozen CPU affinity adapters
change in these reruns. The corpus retains the Phase25 reference manifest and
primitive/worker suites retain their separately compiled pinned-TypeScript and
Phase27 references. The worker admission suite uses the same prospectively
reviewed Phase30 erased-Let refusal amendment; the earlier obsolete assertion
failure remains preserved. No unsupported path or observed failure was hidden.

CPU4's outer selected-upstream step took42.20 seconds. CPU7's serial steps
totaled approximately154.37 seconds, including118.23 seconds of corpus validation
and14.24 seconds for component plus HVM acquisition. These are concurrent
correctness-acquisition costs, not controlled performance measurements.

The root separately completed `transfer-14/report.json`: all ten original
programs were freshly compiled by the checked candidate and their complete
reference scalar results matched. That acquisition was not duplicated by the
reviewer. The full clean original-program and compiler-cost matrices are
separate windows; do not substitute these correctness durations for their
results. Release installation/relocation, the proposed81-row backend renewal,
and the possible811-row JS extension also retain separate gates and receipts.
No fresh whole-frontend or full-backend claim follows from this selected batch.

The independent execution note is
[final-selected-independent-run.md](final-selected-independent-run.md).

## Earlier candidate12 acquisition

The frozen attempt12 passes every newly run selected integration gate below.
This validates the candidate image; it is not yet a claim of installed release
verification, new whole-frontend conformance, or final measured performance.
The [prospective checklist](../../design/phase30/final-integration.md) separates
those remaining decisions and measurements.

| Artifact | SHA-256 |
| --- | --- |
| Checked bootstrap parent | `0ed4aa5fdcb8347ca8834211fe6ffb2e20ff86eda41e659856964fe1e48c30df` |
| Selected equality-derived API | `633ac3a02f032b9defef4e9de820381fffc5f6ed77ddcd26164c04618fb36a00` |
| Frozen runtime | `a3547a8854b45c65fd804f106868dc28540118b611d85fe99ba0e3d199c66ef0` |
| Pinned Base | `c742fae9c49b14f0cc9128429a2c6109364c8a933a142f2c90b9f2e5fd976661` |

All paths below are under `selfhost/build/phase30/final-integration-plan-12/`.
The fresh gate launch reports are `gate-launch-cpu4/report.json` and
`gate-launch-cpu7/report.json`, both complete and passing. The plan verifies its
consumed identities before and after the batch. Its frozen launcher derivation
changes resource affinity to CPU7 and binds the original tool root; tests,
oracles and child limits stay unchanged. The upstream workflow retains CPU4
from the checked manifest. The two acquisition CPUs were allowed concurrently;
these durations are validation costs, not controlled timing comparisons.

| Fresh gate | Result | Receipt directory |
| --- | --- | --- |
| Selected upstream JS execution | 15/15 pass on both sides; zero exact differences | `upstream` |
| Scalar primitive oracle | 56,205 scalar checks; all58 observation rows pass | `primitive/comparison` |
| Native worker oracle | 3,759 scalar checks and14 additional observation rows pass | `worker/comparison` |
| Nested-worker oracle | 144 checks pass | `nested/comparison` |
| Primitive admission/refusal | 1,129 guards and25 execution observations pass | `primitive-guards/comparison` |
| Worker admission/refusal | 40 guards and2 execution observations pass | `worker-admission` |
| Checked library corpus | 23 libraries,127 complete points pass | `corpus` |
| Real compiler membership component | 22 complete observations pass | `component` |
| Whole HVM5 program | Exact complete stdout; empty stderr | `hvm` |

The HVM output is exactly:

```text
&S{#0{()},#1{()}}
- Itrs: 79 interactions
```

Primitive/worker execution retains saved pinned-TypeScript and pre-worker
Phase27 reference modules. The23-library corpus retains the exact Phase25
reference manifest SHA-256
`e8569b75a72ecc2f108d5235525e4901a94bbc2d12affd56685c14d05edb6661`.
The worker guard runner is the already reviewed Phase30 admission amendment:
erased lets refuse the scalar fast path while the original suppressed-RHS
execution witness remains. Only image bindings change for this fresh run; the
obsolete admission failure remains in its earlier evidence directory.

The selected upstream gate took41.29 seconds. CPU7's serial validation steps
took approximately151.10 seconds in total, including116.05 seconds for the
corpus and13.70 seconds for component plus HVM. This is a bounded integration
loop after image freeze, not the cost of one small optimization experiment.

The parent's separate `transfer-12/report.json` records fresh checked emission
and complete scalar results for all ten original programs. That acquisition is
not repeated here. `final-transfer-plan-12/plan.json` freezes ten individual
TypeScript/Phase29/candidate measurement configs with the unchanged five-sample
transfer protocol. Its retained launcher derivation only binds the original tool
root and prospectively changes the outer budget from600 to1200 seconds; all
per-child limits, calibration and warmup rules remain unchanged.

`compiler-cost-config.json` separately freezes the ordinary compiler comparison
on the historical fac06128 source, with three rotating observations each for
TypeScript, Phase29 and candidate12. It reuses the maintained Phase23 matrix
and Phase8 worker. Generated-program timing and ordinary compiler checking must
run in separate exclusive windows and receive separate reports. Neither has
run as part of the integration batch described here.

The build's36 exact controls and independently owned Phase30 rule-specific
controls retain their own receipts. Historical3,026/3,026 and196/196 frontend
totals have not been rerun by this selected batch. Historical shared failure
statuses remain unchanged. Release installation, provenance verification and
the42-step ordinary/relocated smoke remain separate post-selection gates.

An independent static review of the integration plan, consumed launcher diffs,
compiler-cost config and transfer derivation found no scope or provenance
blocker. Each consumed CPU substitution occurs exactly once in the relevant
launcher and changes no fixture value. If a subsequent runtime change is
promoted, these receipts remain attempt12 evidence; affected gates and configs
must be freshly rebound to that image rather than relabeling this batch.
