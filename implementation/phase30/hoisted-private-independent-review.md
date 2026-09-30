# Independent review of private helper hoisting

Independent review found no semantic blocker for the exact acquired actual12
helper and original Mandelbrot modules in the
[frozen hoisting experiment](../../design/phase30/hoisted-private-helpers.md).
This conclusion is scoped to those audited modules and the existing standard
host-intrinsics/private-code observability contract. It is not approval for a
general emitted-JavaScript optimizer or a production implementation.

The owner's Acorn audit retains identical declaration bytes and rejects any
duplicate private name whose declaration differs. Its lexical resolver accounts
for parameters, block declarations, nested scalar arrows and for-loop bindings;
only other collected private helpers and Math/Number/BigInt may remain free.
All private identifier uses must be declarations or saturated bare calls, so a
private function identity cannot escape through a return, data value, property,
constructor use or public export. The injective codepoint names remain unchanged.

A separate independent audit, `inspect-hoist-scope.mjs`, checked the complete AST
of both baseline and hoisted variants for both workloads. All four pass:

- Math, Number and BigInt have no shadowing binding anywhere in the module.
- Private helper names have no alias/shadow binding, export or escaping use.
- Every private call outside another private helper belongs to a callback that
  is the sole direct argument of `exactCode`; matching parameter spelling alone
  is not used as the proof of deferred public entry.
- The baseline has no colliding module-scope private names. The hoisted output
  has exactly its recorded unique helper names and no top-level binding collision.

The raw independent result is
`selfhost/build/phase30/inspection-hoist-scope-01/report.json`, with parser source
hash, Node identity, consumed audit and all four module identities. This closes
two assumptions in the original derivation's otherwise local scope audit: that
its allowed intrinsic names really refer to globals, and that the recognized
public callback is actually constructed through `exactCode`.

Moving the declarations changes allocation lifetime, private identity sharing
and optimization feedback sharing together. It leaves their scalar computation
and direct call arguments unchanged. Public owner/helper descriptors and each
owner's guard closure remain in their original locations. A public binding or
metadata mutation therefore still causes the same original generic fallback;
the hoisted private bodies neither read those descriptors nor replace their
snapshots. Definition initialization and forward references are additionally
covered by the owner's separate diagnostic counters, which must remain outside
timed modules.

The owner reports passing existing helper numeric/ABI/exact-entry controls and
whole-program numeric, public-boundary and depth controls. Those executions are
separate from this independent static audit. Timing must still establish whether
deduplication is useful; the declaration and byte reductions alone establish no
speedup.
