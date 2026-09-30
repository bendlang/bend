# Isolate lexical bindings for private scalar helpers

Prospective generated-JavaScript spelling ablation, after checked attempt07.
The current private scalar region stores its four helper functions in a private
null-prototype dictionary and calls them through literal property loads. A
disposable earlier region used lexical functions and was faster, but also
changed admission, callback layout and primitive emission. That comparison
does not identify dictionary dispatch as the cause.

Freeze the attempt07 Mandelbrot helper fixture and replace only its private
`$R` dictionary with four uniquely numbered lexical function declarations.
Rewrite every exact `$R["name"]` reference within that same private IIFE to the
corresponding lexical name. Keep the function parameter and body expressions,
function declaration order, loop, input validation, closure guard, exact-entry
permission, generic fallback, public G definitions, runtime, scalar Number and
BigInt representations, and workload unchanged. The functions remain private.
The helper graph is acyclic; forward references are resolved before any public
entry can run. No public descriptor is replaced or captured later.

The intervention changes lexical binding rather than compiler admission. Reject
unexpected dictionary accesses, duplicate helper names, computed keys, aliases,
preexisting generated private names, or a source identity other than the frozen
fixture. Record the exact removed declaration and each rewritten occurrence.
The derivation must assert that it changes only the single private region and
that no `$R` identifier remains. This is a diagnostic output experiment, not a
compiler-source edit or a claim that property lookup is the measured bottleneck.

Before measurement, compare the derivative with unchanged attempt07 using the
existing 130 ordinary ABI/getter/effect/error observations, 72 scalar arithmetic
and long-loop runs, and nine exact-entry/reentrancy observations. Preserve the
stable-intrinsics scope and previously documented prototype and engine-wording
limits. Both sides of this ablation have the same runtime and admission.

Use the existing clean paired screen and long-warm confirmation protocols at
the unchanged 128-iteration helper point, arguments `[128,524800]`, expected
result 128. Obtain the lead's exclusive timing slot first. Keep this variant
separate from guard removal, fallback outlining, counter representation,
larger-region admission and all other interventions. Report output bytes and
per-process samples even if it does not improve speed. If useful, compiler
integration should replace the dictionary plan's spelling with numbered lexical
bindings; it should not introduce another call lowering or semantic guard.
