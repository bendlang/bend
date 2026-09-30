# Prospective ablation: consume fresh non-tail argument arrays

Agent-generated,2026-09-30. Separate from P30-001 direct entry. No timing or
compiler changes have yet tested this mechanism. Phase30 baseline/protocols apply.

Every ordinary emitted non-tail application constructs a new JavaScript array
literal. The runtime's generic `apply` immediately copies that array with
`args.slice()` when the descriptor has no bound prefix. The caller retains no
reference to that literal. A separate internal `callOwned(f,args)` may therefore
consume it while public `call` continues to copy. Bound-prefix concatenation and
both oversaturation slices remain. Generic matcher vectors, foreign-provided
argument vectors and runtime-internal calls retain the old copying path.

The first saved-output intervention adds an optional owned flag to `apply` and
an internal `callOwned` wrapper. Only emitted `call(...,[...])` sites in the
program section change. Do not change `jump` or `force`: a captured bounce can
retain its argument vector across forcing, so tail ownership requires a distinct
contract. No function identity, G lookup, public descriptor, evaluation ordering,
loop, arithmetic or record representation changes are included.

Compare the existing small Mandelbrot fixture unchanged/candidate/upstream on
its already retained120-point oracle; run separate ownership, partial,
oversaturation and effect/error controls including functions that mutate their
received argument array. Measure the existing point128/524800 with Phase29
screen then confirmation if the screen supports a gain. Repeat on the small
edit-distance row only after the first result, keeping source inputs fixed.
Counter copies are separate from clean timing. Record site counts and exact
bytes before/after; prototype code is not a compiler release.

Falsify on any changed output/ABI/order/alias behavior, absence of removable
copies, or clean timing regression. If supported, implement the smallest emitter
and runtime change with independent review and measure combined versus each
individual mechanism before promotion. Avoid duplicate apply implementations.
