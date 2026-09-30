# Independent residual-cost ablation review

Static review found no blocker in the outlined-fallback derivative. The separate
guard-bypass derivative remains a diagnostic for unchanged descriptors and is
not eligible for production. No additional execution was needed for this review;
the experiment owner has already run the applicable ordinary, prototype,
arithmetic and exact-entry suites on the outlined output.

Reviewed inputs are `selfhost/tools/performance/phase30/residual-derive.py` and
its frozen `selfhost/build/phase30/residual-01` outputs. The derivation moves the
1,046-byte generic successor fallback into one private lexical function. The
original public callback reads its seven slots first, then evaluates unchanged
entry/input/snapshot guards. Only the failing branch calls the private function
with the saved values. It neither rereads the host frame nor reevaluates inputs.

The moved expression has no dependency on JavaScript this, arguments, dynamic
eval, or the callback's identity. Its generated local aliases and closures keep
the same value bindings; module runtime and G references resolve in the same
lexical scope. The outlined call passes existing values and introduces no
property lookup on them. Its result is returned directly, preserving the
original bounce/build forcing boundary and generic recursive target lookup.
The additional private frame does not accumulate through the existing trampoline.

The owner reports all 146 ABI/effect/prototype observations, 72 scalar oracle
runs and nine exact-entry cases passing against unchanged attempt07. This
independent review does not broaden that evidence into full backend conformance.
Public function source text and engine-generated stack traces are not claimed
byte-identical. The two ablations must remain separated in timing: outlining
preserves admission, while guard removal intentionally weakens it.
