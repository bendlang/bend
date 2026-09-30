# Independent general tail-Let controls

Prepared before deriving or executing any actual13 variant. This supplements
`general-tail-let-statements.md`; it does not expand the maintained compiler.

`review-tail-let-derive.mjs` uses the pinned Node-bundled Acorn 8.16.0. Each
actual acquisition must verify the checked attempt13 receipt, source, API,
runtime, Base and driver identities, then preserve the complete runtime prefix
byte for byte. It admits only exact, nonempty, synchronous expression-bodied
arrow calls with distinct `x<number>` parameters. Spread/default/destructuring
and mutable parameters are refused. The write check is intentionally
conservative: even a same-named write under a nested shadow is refused. Direct
eval or with anywhere in the generated suffix stops derivation.

All argument expressions execute in order into fresh comma-initialized
temporaries before entering the source-binder block. Every original RHS and
terminal expression remains an exact source slice. Only complete returned
tail chains become statements. Select innermost nonoverlapping ReturnStatements
per round, reparse after each round, and require exact complete reconstruction
by reversing the retained edit history. Bounds are 32 rounds, 4,096 tail Lets,
and a four-MiB input; hitting a bound fails acquisition rather than partially
claiming the proposed experiment.

`review-tail-let-controls.mjs` independently checks:

- Parallel and nested shadowing, including RHS closures retaining old outer
  bindings and escaped closures surviving repeated calls/loop iterations.
- Ordered getters, later RHS errors, terminal errors, finally order and
  deferred field/function effects.
- Anonymous function, arrow and class names; class static name observation;
  named values; function arity and constructibility shape.
- Lexical this, arguments and new.target, object-literal terminal expressions,
  preserved primitive IIFEs, signed zero/NaN and administrative-name collisions.
- Multiple rewrite rounds for nested returned callbacks, exact runtime-prefix
  preservation and unsupported/mutable syntax refusals.

These are program-value, effect-order and ordinary ABI controls. This experiment
does not promise byte-identical Function.toString or stack-frame traces after
removing an internal arrow activation. Existing public callback kind/arity/name,
saved closure behavior, raw/partial/exact/oversaturated entry, descriptor reads,
deferred work and exception values remain required. Actual Mandelbrot and
edit-distance variants additionally require the existing public-boundary,
entry, full-state and original-result controls before timing.

No acquisition, correctness or timing result is implied by this prospective
file or by writing the tools during the exclusive timing pause.
