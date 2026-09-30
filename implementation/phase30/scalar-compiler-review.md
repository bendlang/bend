# Independent review of the general scalar-region compiler

This file records static findings before a checked implementation artifact is
available. It does not claim that the compiler changes build, select the region,
or pass execution controls. The first combined acquisition timed out; the lead
preserves that attempt separately. Subsequent diagnosis found an immediate
upstream checking error in `j_nat_loop_region`, followed by a timeout in error
rendering. This is not evidence that region analysis or descriptor capture
made compiler execution slow. The raw diagnostic and repair are tracked by the
lead and implementation agent.

## Integration and admission

The public Nat matcher and successor descriptor remain the existing wrappers.
The fully entered successor callback reads each original argument-vector slot
once, in its original order, before checking scalar representations and helper
snapshots. Both private and fallback loops use those saved slots. A getter or
reentrant callback during a slot read can therefore change helper state before
the guard; the fallback must see that change without rereading the frame.

The private copy preserves the owner lambda spine and final self-tail application
spine. Existing countdown code still controls the BigInt counter, simultaneous
next-state values, immutable iteration aliases, and final Zero computation.
The public Zero arm is unchanged. JCall, JSlot, and JIf exist only in the private
emission copy; scalar annotations preserve the type information consumed by let
context construction. No ordinary normalization of private nodes is required.

Helper admission currently restricts parameters and results to native U32 and
Bool. Nat may occur in the owner state and primitive operands; F32 helpers,
records, arrays, foreign calls, dynamic calls, computed globals, erased helper
parameters, and unknown expressions decline. Leading native Bool matches must
be exhaustive and may have branch-specific live lambda binders. Parallel let
right-hand sides use the old environment, while the final body uses the extended
environment. These distinctions are visible in the new independent controls.

The helper graph only caches completed definitions. Active names reject true
direct and mutual scalar cycles before completion. Bounds limit graph depth,
helper count, source size, expression depth, binding count, and shared lowering
fuel. Result-type consistency continues to rely on the checked input core;
these recognizers are not a replacement typechecker for arbitrary injected IR.

No static semantic blocker was found in this integration under the declared
standard-intrinsic contract. That is narrower than an executable validation
result. Definition-time snapshot guards were independently exercised in
[scalar-runtime-guards.md](scalar-runtime-guards.md); that runtime test alone
does not prove the compiler captures every actual helper.

## Prepared independent controls

`review-scalar-compiler-run.mjs` accepts baseline and candidate modules emitted
from the same checked Mandelbrot fixture. It requires an actual private-region
marker and captures for all four expected helpers. It covers mutation before
the first public call; G and metadata getters; descriptor replacement and code
call hooks; invalid, boxed, proxy and coercible scalar inputs; raw callback slot
accessors; reentrancy; prototype-hook fallback; public partials; independent
arithmetic oracles; and a 50,000-iteration stack control. Inputs, tool bytes,
ordered traces and any first mismatch are retained in a fresh result directory.

`review-scalar-compiler-admission.mjs` invokes the actual checked j_library on
synthetic books. Positive books cover later G definitions, a Zero-arm helper,
reverse Bool branch order, transitive helpers and parallel binding shadowing.
Negative books isolate true scalar Lam recursion, unknown and higher-order
expressions, computed globals, foreign helpers, application saturation, erased
parameters, templates, native-owner provenance, refined types and graph depth.
The existing Nat-worker marker distinguishes region refusal from refusal of
the enclosing older optimization. Accepted books execute independent results
and mutable-public-ABI controls. Cyclic and foreign books are never executed.

These tools are prepared and syntax checked, but have not yet run on a new
checked region compiler. Synthetic books intentionally do not claim frontend
admission. The ordinary source language rejects unresolved live forward
declarations; the forward G control therefore belongs in the synthetic emitter
suite, not the checked source fixture. Likewise the checked fixture's recursive
Nat helper can refuse at its signature before reaching cycle detection; the
separate U32 Lam cycles are the direct recursion-guard witnesses.

## Attempt03 execution results

The checked attempt03 subsequently became available. The actual admission tool
passes all 22 books and 12 executable scalar/public-ABI observations; evidence
is `selfhost/build/phase30/review-scalar-compiler-admission-01/report.json`.
The actual checked Mandelbrot comparison passes 130 ordered/ABI observations
and 72 independent numeric-oracle runs, including 50,000 iterations; evidence
is `selfhost/build/phase30/review-scalar-compiler-run-01/report.json`.
Both suites retain consumed tools, exact emitted modules or input hashes, and
verify those inputs remain unchanged. These supersede the earlier pending
execution status above, not its description of what was known beforehand.

These passing Phase29 comparisons do not establish all prior semantics. A
separate comparison to the compiler used in Phase28 exposes five inherited
Nat-worker scheduling/live-self failures; see
[nat-loop-scheduling-review.md](nat-loop-scheduling-review.md). Those are
correctness blockers despite the new scalar region's admission and ordinary
execution successes.
