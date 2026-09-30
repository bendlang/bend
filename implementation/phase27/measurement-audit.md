# Phase27 independent measurement audit

**Pass. Promote only the shared-helper variant, subject to the separately recorded correctness and installation gates.** Its measured benefit is modest and workload dependent. The inline variant's clear short-window regression remains a rejected result.

The [audit data](measurement-audit.json) independently verifies all four complete acquisitions: **360 timing samples,72 calibration processes and72 output-check processes**, across24 case/window combinations. Every raw launch/stdout/stderr record agrees with its embedded report; all504 processes succeed with exact expected results. Every module/tool identity still matches, checksums and medians recompute exactly, all samples are retained, recorded acquisition intervals are serial, and actual child affinity/Node flags match CPU3/Node24.18.0/stack4096KiB/heap1024MiB. No runtime, build or benchmark was executed by this audit.

Compilation, import and warmup are outside `executionMs`; exported calls, result assertions and checksum updates are inside. Each fresh process checks every returned U32. Side-specific repetitions match the recorded calibration formula and stay fixed across its five samples. Reference and baseline module bytes are identical across windows; each candidate's bytes stay identical within its two protocols. Results from separate windows are not pooled.

## Four separate observations

Factors below are baseline time / candidate time; above1 means faster. They describe selected generated-JS programs, not current full self-emitted compiler throughput.

| Variant and protocol | Term substitution | Actual compiler membership | Boolean worker |
|---|---:|---:|---:|
| Inline, short warmup |0.8328×|1.0399×|1.1785×|
| Inline, longer warmup |1.0108×|1.1319×|1.0371×|
| Shared helper, short warmup |0.9946×|1.0263×|0.9925×|
| Shared helper, longer warmup |0.9966×|1.0594×|1.0421×|

The inline term regression is20.08%, with nonoverlapping observed old/candidate ranges in the short window. Its approximately1% longer-warm difference overlaps those sample ranges and does not establish a meaningful term speedup. Both facts remain reported.

For the shared helper, term is effectively flat in both windows; the small short-window Boolean change also overlaps sample ranges. Longer-warm membership and Boolean gains have nonoverlapping observed ranges. Shared short-window Boolean-choice/scalar cases improve1.0575×/1.0573×; partial application improves1.0235×. Match-remaining-args has a1.0240× median improvement but overlapping ranges, so that small result is less persuasive. Host-boundary and numeric-table differences likewise overlap their observed ranges.

Five samples establish these observations, not confidence bounds or a universal gain. Promotion is justified as a small guarded improvement supported by an actual compiler helper and several kernels, without the inline variant's unresolved material regression. It would not justify claiming every workload improves, a term-substitution gain, or whole-compiler acceleration.

## Warmup and duration claims

Both floors are enforced: short windows require at least8 calls and100ms; longer windows require at least200 calls and500ms. Every sample meets its relevant pair. The runner's conjunction is correct, and the longer-warm launchers preserve the original checking, ordering and timing machinery through a recorded exact transformation.

Measurement uses a calibration **target**, not a minimum duration. Actual blocks span53.59–181.69ms (short01),400.27–529.61ms (warm01),53.69–184.49ms (short02), and356.71–546.89ms (warm02). The1M-call cap also applies. Do not relabel these as guaranteed150ms/500ms blocks. The V8 traces explain why further warmup was investigated; they are not substituted for uninstrumented results or proof that the initial measurements were invalid.

## Mechanism and remaining limits

A second read-only audit confirms all18 rows of exact operation counters are identical between inline and shared acquisitions. The shared acquisition uses the correct preserved old runtime and new runtime per side, verifies their exact module prefixes, and passes all seven counter controls per process. Therefore the counted fn/apply/bounce reduction alone cannot predict the differing short-window behavior; host code shape and optimization history matter.

The counter interpretation in [arm-review.md](arm-review.md) remains essential: the final bound function and field-vector slice still exist. Generic `partialApplications` and `argumentCopyArrays` cease observing work moved into the specialized helper; those decreases do not mean all corresponding objects/copies disappeared.

Recorded process intervals establish serialized acquisition, not full-machine physical isolation. Source review, finite semantic gates and this timing audit remain separate evidence. The user-visible result is a guarded runtime/backend specialization with modest selected-program gains; broader backend semantics, future engines, other machines and current full-H performance remain outside these measurements.
