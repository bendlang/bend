# P13-005 — Remove intermediate tag-selection steps, retain selected body frames

Prospective conditional followup, 2026-09-28. Owner: root. No candidate or
measurement yet. Run only after the explicit-worker pilot has established its
correctness/allocation tradeoff. This records the alternative before testing it.

## Hypothesis

The six nested tag choices in `norm_eval_node` allocate a branch closure, Unit,
trampoline message and singleton argument array at each failed tag. Explicit
worker lifting removes closures but adds capture arguments. Instead, flatten
only the intermediate selection steps, retaining the original literal arrow
and execution frame for each selected body:

```js
return run_tail(c1 ? body1 : c2 ? body2 : body3, {$: "Unit"});
```

Evaluate conditions once, in their original order. Keep every body (especially
its non-tail calls) in its original arrow. This is not Phase12 broad branch-body
inlining. No normalizer-source change or runtime/ABI change is permitted.

## Admitted shape and obligations

Start with `norm_eval_node` only, then expand by the same rule only if correctness
and controlled whole-source results justify it. A removable false arrow must
have exactly one returned literal Unit choice and no other statements; its Unit
parameter must have no reads, writes or nested captures anywhere in that body.
Keep the nested choice's true/false arrows and their parameter names intact.
Reject unknown syntax, rebindings, nested functions and unsupported conditions.

Only nested conditions with the exact generated tag comparison shape
`$String$eq$($tg$(identifier), "literal-tag")` are eligible initially. Verify
the actual helper bodies and protected bindings; do not speculate across
`run_loop`, `wnf`, arbitrary calls, projections with additional computation,
local declarations or the separate Rwt proof check. Keep all tags/tests in order;
do not cache the tag or switch to native equality.

The helpers are bounded on the actual compiler's ordinary native-string Term
tags. The generic String equality fallback and hostile getter values mean this
is not a universal claim that every possible JS object has a total condition.
Independent controls must compare native and represented strings, read/effect
order, thrown errors, unselected bodies, nested closures and Unit identity.
The existing forced-observation contract excludes private unforced JMP identity,
reflection and hostile prototype mutation. Capture/value construction of the
original selected arrow remains unchanged.

Moving even selection into the producer can affect stack frames. Require actual
fresh and exact53/60 request histories at4MiB; source-level reasoning cannot
substitute for those tests. No full-source timing on a stack-failing artifact.

## Evidence and stop rule

Freeze every input, helper and candidate; record removed static selector steps
and unchanged body/runtime/public-wrapper bytes. Keep failed artifacts and
original launch error/signal/timeout/overflow fields. Use the shared structural
view only; do not add a second scanner. The independent reviewer owns semantic
controls and the measurement owner owns matched histories.

For a surviving artifact, root runs fresh-process opposite-order comparisons on
the same complete source, exact hosts and separately validated Base caches,
Node24.18.0, CPU0,4MiB stack and4GiB heap. Pause other compiler/archive jobs.
Count all current/historical helper and test code. Expand only with useful
whole-source evidence; promotion uses the master design's roughly20% gain or
compelling speed-plus-simplicity criterion and all integration gates.

If the explicit-worker or selection pilot gives no justified investment path,
stop and preserve the usable Phase12 release. Outcomes go in
`implementation/phase13/selector-fusion.md`, not back into this plan.
