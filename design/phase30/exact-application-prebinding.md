# Preserve the enclosing matcher application boundary

Prospective repair, frozen before runtime edits or candidate execution. The new
exact-field widening has been rejected and reverted after an actual public-cell
counterexample. A related static concern affects older partial prebinding:
matcher1p copies projected field vectors during its callback, while matcher1
returns a bounce that defers the field application. An enclosing oversaturated
application can read its copied argument-vector length between callback return
and forcing. Foreign field copies/getters must not move across that boundary.

First compare the actual runtime helpers with a literal three-argument arm and
two supplied fields. Cover exact, partial, oversaturated and raw matcher entry;
throwing outer lengths and field copies; and a code.call hook that observes the
raw result before forcing. Preserve the failing runtime and tool in a fresh
directory. If the concern is not reproduced, do not change the runtime merely
on the strength of this plan.

If confirmed, reuse the already reviewed exact-application entry token rather
than introduce another representation or trust marker. Rename natWorkerCode to
exactCode, reflecting its shared responsibility, and update only that reference
in worker.bend. Register matcher1p's public callback with this helper. Consume
permission before destructuring the callback argument vector. After the same
projection, length read and literal code construction, an unprivileged invocation
must return the original generic result:

```js
n ? jump(fn(arity, code), projected) : fn(arity, code)
```

That branch must not slice or reread the projected vector. An actual exact
application may use the current prebinding implementation, since exact apply
has no later length/arity observation. Raw entry, overapplication, callback call
hooks, and reentrant same-vector invocation retain the generic delayed behavior.
Public descriptor fields and arities remain unchanged. Keep the conservative
count-less-than-total compiler admission; this repair does not reinstate the
rejected widening.

Repeat the seven paired runtime controls, the broader existing arm suite, and
the actual preworker Nat-loop/entry controls on the combined checked compiler.
Record cost on unrelated generated programs because more callbacks will use
the shared entry wrapper. The runtime change and its semantic observations are
separate from any clean performance result.

## Preserve the callback's callable kind

Independent reflection on actual emitted old/new modules found that reusing an
ordinary function wrapper changed matcher1p's prior arrow callback into a
constructible function with an own prototype property. Name and length stayed
unchanged, but callable kind is an avoidable public-ABI difference. Preserve the
counterexample; do not change the already frozen attempt06 snapshot.

For the next candidate, give exactCode an optional arrow mode used only by
matcher1p. Both anonymous one-argument wrapper forms delegate immediately to one
module-level entry consumer, which checks code/vector identity and consumes the
token before calling the inner implementation. The Nat successor code keeps
its original ordinary-function kind. This shares the token rule without adding
another per-instance intermediary closure. Retest names, length, own properties,
constructibility, seven matcher scheduling scopes and nine entry/reentrancy
controls. Any diagnostic runtime-prefix replacement is distinct from a new
checked compiler acquisition; repeat integration after the lead builds it.
