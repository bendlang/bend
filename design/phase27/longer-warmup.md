# Prospective Phase27 warmup amendment

Frozen after timing01 and diagnostic traces, before new clean timing. No compiler
source or runtime changes are involved. The original135 samples remain valid for
their >=100ms/eight-call protocol; do not discard them or relabel them as steady
state. The substitution point warmed only20 calls and measured24/26 calls, with
old/candidate medians4.075/4.894ms. Calibration already varied about2.4–6.3ms/call.

Separate V8 diagnostics observed optimization/deoptimization through calls50–150
in both variants, including lazy deoptimization in force/apply. Calls150–350 had
no such events and roughly2.35–2.44ms/call under instrumentation. This supports a
phase-timing explanation, not a new clean comparative ratio or guaranteed gain.

Run a fresh clean comparison on three named cases: term-substitution (regression),
compiler-membership (real transfer, small initial gain), and boolean-worker
(strongest initial apparent gain). Same sources, outputs, inputs and CPU3/Node24
as timing01, five fresh processes/output in rotating serial order. Set warmup to
**at least200 calls and500ms**, then calibrate side-specific repetitions to target
**500ms** (same1M cap). Output checks and module identity gates stay unchanged.
Stop other agent execution during timing. Every sample remains in the report.

Report both protocols separately. The follow-up resolves the representative
regression and tests robustness of two positive claims; it is not permission to
replace inconvenient samples or silently extrapolate unmeasured workloads. If a
material persistent regression remains, reject or separately correct the source
rule before promotion. Do not adopt workload-name exclusions.
