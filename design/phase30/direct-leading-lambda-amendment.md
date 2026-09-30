# Phase30 amendment: direct calls inside an existing loop

Status: prospective plan, frozen before generated-program tests or timing.
Owner: Phase30 analysis agent. This complements the edit-distance record-worker
experiment; it is not a compiler change or a new release candidate.

## Question and scope

Does exposing fully applied, leading-lambda helper calls improve Mandelbrot's
already-lowered `mit` loop, while arithmetic, BigInt Nat values, matchers and loop
structure remain fixed? The Phase29 output has three `asr8` and two `sel` calls
inside that loop. Both helpers are explicit `fn(n,function(a){...})` definitions.
`b2u` is a matcher, not a leading lambda, and remains unchanged. All calls outside
`mit`, including `asr8`'s inner call to `sel` and `sel`'s call to `sel.go`, remain
unchanged. This scope makes a null result informative rather than an invitation
to silently expand the transform.

Use the exact Phase29 emitted Mandelbrot module (`11977282...`), paired with its
unchanged pinned TypeScript module (`037f070e...`). The derivation manifest must
record full hashes of input/output/helper/tool/plan/runtime. Original public `G`
descriptors and exports remain unchanged. The new module is disposable generated
JavaScript, never described as a compiler-produced candidate.

## Transformation

Extract the two structurally admitted function bodies; assert the exact leading
lambda arity and parameter-bind count, no `this`, no unknown parameter-array use,
and exact static call-site counts. Introduce private functions with positional
parameters and the original expression body, retaining final `force` behavior.
Replace only the five selected `mit` call sites with private guarded invocation.
The live function lookup occurs before argument expressions. Arguments are then
evaluated exactly once, left-to-right, before the private guard, matching the
original `call(get(G,name), [args])` evaluation boundary.

The private guard admits only the captured ordinary descriptor with unchanged
own data fields `arity`, `code`, `env` and `bound`; use own property descriptors
so guards do not trigger a newly installed accessor. Require the captured bound
array and its own length value zero. Reject changed object prototypes, own
`io`/`typeName` fields, or inherited `io`/`typeName` fields on Object.prototype.
Identity comparison precedes object inspection, so a replacement Proxy falls
back without extra traps. The fallback is the original `call(f,args)` on the
already-resolved live value, with argument values already evaluated.

This permits ordinary G replacement, descriptor property mutation, changed
arity/bound values and installed getters to retain the existing behavior through
fallback. Standard intrinsic Object/Reflect/Array operations are assumed;
monkeypatching Array.prototype.slice to observe administrative copying is outside
this source-language optimization experiment. No source-level operation, foreign
getter or argument evaluation may be skipped. The independent reviewer must
challenge the public mutation and accessor scope before interpreting timings.

## Correctness and counters

Before timing, compare against untouched Phase29 output and pinned upstream:

- original helper outputs across zero/small/multiple iteration counts, selected
  U32 boundaries and escaping/non-escaping points;
- original benchmark at sizes 0, 1 and 2;
- partial public calls and unchanged descriptor observations;
- live G replacement, Proxy replacement, code getter/replacement, arity/bound/env
  changes and prototype changes; compare complete transcripts and thrown errors
  against the baseline for the same invocation;
- no timing claim from this correctness runner.

Instrument separate copies to count generic application, descriptor creation,
bound arrays, copied argument slots and jumps. Verify the transform removes the
intended sites rather than changing input work. Counts are named runtime sites,
not total allocations. Clean modules must not contain the counters.

## Measurement and decision

No clean timing runs until the lead grants exclusive timing access. Reuse the
Phase29 rotated fresh-process harness, CPU3, Node24.18.0, fixed limits and exact
inputs. First use the existing short fixture-sized screen; freeze the actual
configuration before execution. Measure original Phase29, the direct-call
prototype and pinned TypeScript. Import/first call stay separate. Follow a
promising short result with a longer-warm confirmation and transfer before a
compiler implementation. If descriptor guards outweigh saved dispatch, retain
that negative result and do not relax public semantics to manufacture a win.

A subsequent unguarded closed-book estimate or Boolean-matcher rewrite, if useful,
requires a separate prospective plan and explicit evidence label. It must not be
substituted for this experiment's guarded result.
