# Share identical closed private scalar helpers

The actual12 helper and original Mandelbrot modules repeat some `$R_...`
function declarations in several owner IIFEs. Test one different mechanism from
the constant-binding experiment: hoist one byte-identical copy of each private
helper to module scope and remove all owner-local copies. Preserve each unique
function declaration verbatim, all call sites, public callbacks, guards and
runtime code. This changes private function identity/lifetime and sharing of
JavaScript optimization feedback together; it is not a binding-constness test.

Use the pinned Node's embedded Acorn 8.16.0, following the existing Phase25
structure tool. Record parser source hash, Node hash and every source receipt.
Do not install a package or use a fallback text scanner if that parser is absent.
Analyze immutable actual12 checked emissions and refuse an unrecognized shape.

Group private function declarations by the exact injective generated name.
Duplicate declarations must have byte-identical parameter/body/declaration
bytes. Otherwise reject the entire attempt. Lexically resolve every function's
identifier reads with function, block and for-loop scopes; predeclare local
let/const bindings for scope resolution. No owner slot, guard, G lookup or
captured mutable object may remain free. Initially allow only other collected
private helpers and the standard Math/Number/BigInt primitives as free names;
any other name requires a separate review, not silent admission.

Across the complete AST, every occurrence of a private helper identifier must
be its declaration or the bare callee of a saturated ordinary call. Reject
property/constructor/value uses, shadow declarations, dynamic function metadata,
eval, this, arguments, new.target and unfamiliar binding syntax. Bodies can
contain the existing immediate scalar Let/primitive arrows and loops; lexical
resolution must respect nested and parallel scopes. Require all non-helper
private calls to lie in a deferred public callback, never in a definition's
eager initialization expression.

Insert the unique unchanged declarations immediately before the first program
G assignment. Function declarations are initialized before evaluation, and
their bodies run only through the original deferred public entries after all
runtime and definition initialization completes. Remove the original complete
declaration spans. Preserve exact offset-indexed edits and reconstruct the
original source byte for byte. Parse the result again and verify one declaration
per private name and unchanged public G definitions after ignoring only the
removed private declaration spans. New helpers remain unexported.

Before timing, run the independent scalar/original-program oracles, ordinary
root and tree ABI/metadata/raw/oversaturation controls, depth/budget sentinels
where relevant, and the helper exact-entry suite. Add diagnostic counters for
forward private references and require no helper invocation during module
initialization. Those copies are never timed. Report original declaration count,
unique count and byte reduction separately from speed; deduplication does not
establish a performance gain.

Freeze paired helper `[128,524800]` and whole original `[2,0]` configurations
only after gates. Root grants acquisition and timing separately. Confirmation
must respect observed whole-program warmup requirements. No production source
changes are authorized by this probe; a later implementation would explicitly
collect checked helper definitions in the backend, not rewrite emitted strings.
