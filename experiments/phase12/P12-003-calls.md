# P12-003 — Residual choice wrappers and branch tail messages

Prospective plan frozen before probes, 2026-09-28. Owner: calls subagent;
reviewer: root. Baseline is Phase11 `f8244c9`, immutable
`selfhost/build/phase11/integrated-01`, selected API
`63c861e900450ab2045474d6c822371d30c56019521a12c13d8e4c62009ddf1f`.
Upstream remains `b2111cf43244e65f76ddc278ee695e669f720cbf`.
Report: [calls](../../implementation/phase12/calls.md).

## Claims and alternatives

First static inspection finds the native backend's `nt_choose` has the same
verified body as the already lowered `kc` and `f_choose`, but remains generic.
Hypothesis A: extending the existing guarded literal-thunk transformation to
that exact body removes avoidable wrapper creation in native emission without
changing demand, public ABI, or tail behavior. Count actual accepted call sites
and same-process wrapper operations before deciding whether to build it. This
does not predict a checking gain if those functions are absent from that lane.

Hypothesis B: many version4 choices occur directly in return position. Replacing
the selected Unit branch closure with an `if` block could eliminate the remaining
closure and branch tail-message allocation. The critical obstacle is stack
safety: ordinary recursive calls inside the branch must not become unbounded
direct recursion. A narrowly recognized lowering may instead return an explicit
existing-runtime tail message for a terminal generated-function call. Retain
ordinary values and existing tail messages; do not introduce argument mutation
that could change closure captures. Count eligible shapes and audit the exact
runtime/return protocol before implementing. Stop if a bounded, reviewable rule
cannot preserve raw `$JMP` forcing, Unit-parameter demand, lexical scope, argument
order, exceptions, currying, and the existing stack boundary.

A smaller alternative only expands `run_tail` of a fresh raw literal arrow to its
known tail-message representation. It preserves the branch closure and may save
little after V8 inlining. Do not advance it without operation/profile evidence.
Do not repeat ordinary uncurrying or remove arbitrary `run_loop` wrappers:
raw values may themselves be tail messages, so a result-type guess is insufficient.

## Cheapest discriminating steps

1. Static counts on the exact baseline, with the plan and consumed API/helper
   identities retained. No compiler/heavy jobs while root profiles CPU0.
2. After root releases resources, use CPU3, Node24.18.0, 4MiB stack and4GiB heap
   for tiny same-process operation counts and independent boundary controls.
   Include malformed/raw truthiness, selected-only effects, demand/error order,
   returned functions and `$JMP` objects, nested branches, partial/extra arguments,
   captured values, mutual/self tail recursion, and at least100,000 tail steps.
   Explicitly reject mutated protected bodies/runtime, rebinding/destructuring,
   member callees, and unsupported generated syntax. Keep nonliteral fallbacks.
3. If a candidate survives, prepare one isolated maintained helper/project from
   the frozen baseline and run the genuine checked-B1 workflow with selected
   controls. Keep historical v1/v2/v3/v4 bytes and replay distinct from the new
   transform. Root owns integration, broad gates, controlled timing and release.

This is initially a guarded checked-image derivation investigation. It does not
change the pinned emitter, Bend source, installed release, or emitted user-code
runtime. The standard unmodified runtime/builtins assumption remains explicit;
reflective function/stack strings or hostile prototype mutation are not claimed
invariants. No unchecked derivative is relabeled a bootstrap or fixed point.

All launchers must reject a nonempty spawn error or signal even with status0,
and verify expected output. Preserve failures, original consumed tools, exact
source/API/Base/runtime inputs and negative results. No full-source timing by
this owner; operation counts and concurrent screens do not establish a whole-
compiler speedup. Initial deliverable is a bounded opportunity and semantic-risk
assessment, with a candidate only when the evidence warrants its complexity.
