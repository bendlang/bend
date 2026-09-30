# Reuse scalar regions at profitable ordinary lambda roots

Prospective compiler integration, conditional on confirmation of the
[ordinary-root output experiment](ordinary-scalar-root-regions.md). The first
production scope requires a proved nested Nat countdown in the helper closure.
It does not put guards on every trivial scalar function.

Admit an ordinary nonnative, template-free definition with one complete leading
lambda telescope of 1–32 live scalar inputs and scalar result. Reuse the current
signature, source-size, distinct-binder and label checks. Analyze that lambda
spine with `j_region_prefix`, preserved binders, the root name initially active,
and the existing fresh bounded `JRegionBuild`. There is no permitted recursive
root edge. Helpers use the same completed cache, cycle/depth/fuel limits and
already-proven nested Nat-loop analysis. Require at least one retained nested
Mat helper in the completed closure; Boolean helpers have already become JIf.

Emit the private lexical declarations and complete guard-name list in the same
definition IIFE. Keep the original `fn` arity and ordinary callback kind. The
existing `exactCode` wrapper consumes permission before any slot read. Read all
original live slots exactly once, in order. Then require native scalar input
representations and the existing complete `scalarGuard` before running the
private body. Reuse the existing lambda-spine body emitter on the transformed
term and the original term, respectively. Guard failure or raw/overapplied entry
uses the original generic body with the saved values.

Unify the existing input-check string helper with an explicit predecessor flag:
Nat successor callbacks retain the strict upper bound on the projected first
slot; ordinary lambda roots accept the full existing unprojected Nat range.
Do not change Nat representation, scalar bounds or public coercion behavior.

Ordinary root output is registered through the existing scalar-capture global
emitter. The Nat worker already captures its own descriptor, so its global
assignment bypasses a redundant second capture. Keep one snapshot site per
selected definition. No runtime change, new KTerm node, analysis field, primitive
rule, pattern compiler or recursion algorithm is needed.

Use a fresh checked attempt after the lexical/terminal control. Require the
existing admission/refusal and entry suites, independently authored ordinary-root
admission cases, and the actual emitted pix/rpix oracle and boundary controls.
Add explicit refusals for partial leading telescopes, erased or record parameters,
root self/mutual recursion, labels, invalid native identities and a pure trivial
closure without a nested loop. Test zero and maximum unprojected Nat without
executing an enormous loop: the latter needs a helper whose native Nat argument
is unused on its chosen zero branch. Preserve callback shape, constructor raw
entry, slot getters/reentry and public descriptor mutation.

Measure actual output and the combined terminal/ordinary-root original program,
then the broader original-program set. The isolated prototype is evidence for
the mechanism; its ratios must not be multiplied with another experiment to
claim an unmeasured combined speedup. F32 acyclic roots remain a separate
profitability and semantic experiment.
