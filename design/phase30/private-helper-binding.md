# Isolate private helper binding form

Lexical direct calls were substantially faster than dictionary lookups. Test one
remaining emission choice without adding an analysis concept: the current private
function declarations versus constant bindings to ordinary function expressions
and constant bindings to arrow functions. Only emitter-private `$R_...` helpers
change. Preserve parameter/body bytes, private call sites, public callbacks,
entry checks, guards, runtime and all numeric representations.

These helper values never escape the admitted pure graph; calls are saturated
and direct. Their bodies use no `this`, `arguments`, `super` or `new.target`.
Although a helper body may reference a later helper, no body executes until the
definition IIFE finishes all helper initializations and returns its public
descriptor. Thus constant bindings have no observable forward-reference timing
change in this scope. Keep a checked-source forward-reference witness and the
existing public raw/metadata/descriptor controls. A failed assumption cancels
promotion; do not widen the private-value contract.

Derive both alternatives from immutable actual12 helper and original Mandelbrot
outputs. Parse balanced function bodies, assert exact reversibility of every
edit, and refuse any unexpected use of the private identifiers. Validate the
existing independent numeric/original and host-boundary families. The ordinary
function-expression variant isolates binding constness; the arrow variant adds
function kind. Neither is a new compiler version.

Screen the same128-iteration helper and original small program only after those
checks. Preserve first calls and timed halves. Whole-program tree paths required
15 seconds of warmup in a previous controlled investigation; any candidate
selection needs a prospectively frozen adequate confirmation, not the short
screen alone. A flat or negative result leaves declaration emission unchanged.
