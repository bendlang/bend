# Phase27 second variant: share the prebinding callback

Prospective amendment after the inline candidate's 135 short-window and 45
longer-warm samples, before implementing or timing the shared variant.

The inline candidate removes a function record, generic application and bounce
per selected arm. It passes scoped semantic controls, but enlarges each eligible
matcher and creates distinct outer callback code. Substitution is 20% slower in
the short window, essentially unchanged after longer warmup. Compiler membership
improves 4% / 13% in those respective protocols; Boolean traversal 18% / 4%.
These protocol-specific observations remain evidence, not discarded pilots.

Test a shared runtime helper with arguments constructor name, expected field
count, original arity and a code factory. Preserve the inline variant's exact
projection/length/copy/application branches. Reintroduce the original matcher's
code-factory boundary, without its redundant function descriptor. Returned code
name, source text, environment and bound vector must still match the baseline.
Do not change selection, public arity, result demand or fallback semantics.

Hypothesis: one shared outer callback and smaller generated call sites improve
JIT behavior while retaining the measured reduction in runtime dispatch. Neither
the cause of the short-window regression nor the improvement is assumed proven.
This changes runtime bytes, so provenance and diagnostic guards must use the
correct per-variant runtime. No global replacement of diagnostic expectations.

Preserve the complete inline source patch, attempt and emitted bytes. Build a
new immutable checked attempt, run the same focused, corpus and arm contracts,
and validate the previous numeric controls. Freeze a new timing config against
the identical Phase26 baseline and TypeScript outputs. Run both existing
protocols: all nine short-window cases and the three longer-warm cases, with
the same inputs/order/resources and other execution stopped. Keep all samples.
Compare each new window internally; do not pool separate windows.

Promote only with scoped semantic agreement and a useful measured gain without
an unresolved material representative regression. Otherwise keep Phase26
installed and preserve both rejected variants. Report source/runtime/generated
size changes, actual compiler-component scope and limits separately from speed.
