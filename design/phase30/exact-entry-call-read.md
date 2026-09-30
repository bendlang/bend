# Use the actual method value to authorize exact callback entry

Prospective isolated generated-JavaScript ablation. No maintained runtime or
compiler edit, acquisition, or timing is authorized by this document alone.
This follows inspection of `selfhost/src/runtime/js/core.mjs` at SHA-256
`e716cc08841d169e6f45a6489cf64ac8d3e7157ac82caac3e34170ec57b023d2`.
The initial emitted fixture can be the unchanged attempt07 module, SHA-256
`8e9317debb126b7296b67795e3bca8aba871895b1b8ed15e93458f3c03e271a8`.

## Candidate mechanism

`invokeExact` currently proves that a registered function will use the captured
native `Function.prototype.call` by inspecting its prototype, its own `call`
descriptor, and the prototype's `call` descriptor. It then performs the actual
`code.call` read anyway. The property value required by JavaScript method-call
evaluation is a more direct proof: capture that value once, before reading `env`,
and compare it with the captured native `exactCall`.

For an unchanged registered callback, this removes one `getPrototypeOf`, two
`getOwnPropertyDescriptor` calls and one `hasOwn` check per exact application.
It adds no hot-path argument copy or facade. The WeakSet check, required reads,
entry record, `Reflect.apply`, consumed bit and `finally` cleanup remain. No
speed estimate is justified yet; benefit depends on registered-entry frequency.

Replace only `invokeExact` in frozen emitted bytes. Keep `apply`, `exactCode`,
`enterExact`, scalar guards, helper bodies, generated callback allocation and all
program inputs unchanged. In particular, do not combine this with hoisted/fused
worker bodies or descriptor-guard removal in the first comparison.

The proposed control flow is:

```js
function invokeExact(f, all) {
  const code = f.code;
  if (!exactCodes.has(code)) return code.call(f.env, all);
  const invoke = code.call, env = f.env;
  if (invoke !== exactCall) {
    // Registered callback, but an actual custom method value: no permission.
    // A rare noncallable branch below preserves the engine's existing wording.
    if (typeof invoke !== "function") {
      const code = {call: invoke};
      return code.call(env, all);
    }
    return Reflect.apply(invoke, code, [env, all]);
  }
  const previous = exactEntry;
  exactEntry = {code, args: all, used: false};
  try { return Reflect.apply(code, env, [all]); }
  finally { exactEntry = previous; }
}
```

This is a design sketch, not executed evidence. The rare noncallable facade is
allocated only when JavaScript is about to reject the method invocation anyway.
Its `code.call(...)` expression should preserve the current Node diagnostic
`code.call is not a function` without rereading the original getter or changing
`env` ordering. Verify the exact raw message before accepting that claim. If it
does not match, retain the failure and revise this rare branch; do not add work
to all normal calls or silently normalize messages. Callable Proxies, revoked
callable Proxies, class constructors and throwing custom hooks use the captured
callable path and need separate raw-error controls.

## Why prototype identity is unnecessary for this permission

Only functions created by the private `exactCode` factory are in `exactCodes`.
They are ordinary functions or arrows, never arbitrary host replacements or
Proxies. Changing their prototype does not change their function body. Once the
actual method read has yielded the captured native `Function.prototype.call`,
calling that immutable native function with receiver `code` invokes precisely
`code(env, all)` under the ordinary method's `this` convention. Direct
`Reflect.apply(code, env, [all])` therefore uses the same receiver and argument
vector as that specific native method invocation.

The lookup itself may use an own accessor or an inherited/Proxy prototype. Its
effects and exceptions must occur once, in the original place, before `f.env`.
Unlike the current conservative test, a getter that returns the actual captured
builtin can authorize entry. This deliberately broadens private permission, not
the observable method semantics. The getter cannot wrap or observe the callback's
return while returning that exact native function. A custom wrapper, bound
method, or Proxy function has another identity and receives no permission.

Preserve these details:

- Read `f.code` once at the existing exact-application read point. The earlier
  `apply` validity check remains unchanged. Unregistered/replacement code follows
  the original `code.call(f.env, all)` expression without extra introspection.
- Read `code.call` before `f.env`; read both only once even if the environment
  getter mutates the method or either getter reenters the runtime. A captured
  method must be used after such mutation.
- For a custom callable method, use the captured method with `this === code`
  and the two original arguments `(env, all)`. Do not call `invoke.call`, which
  adds another observable method lookup, or reread `code.call` in fallback.
- Capture the prior token and install a new one only after environment evaluation
  finishes. Consume the matching code/vector/unused token before any callback
  slot access. Restore the prior token in `finally`, including thrown callbacks.
- Oversaturation and underapplication never enter this helper's new fast path.
  No permission is granted by a raw call, a forged extra argument, or reusing the
  same vector from a getter. Extra vector mutation after the earlier exact-arity
  decision must retain that decision's existing evaluation order.
- Do not weaken `scalarGuard`. It still proves purity, live G descriptors,
  primitive-prototype behavior and the whole reachable closure. Exact-entry
  authorization alone is not a purity proof.

The scope retains the existing stable host intrinsics contract, including
`WeakSet` and `Reflect.apply`. The custom-method fallback newly uses
`Reflect.apply`; its lookup must not be claimed transparent to deliberate host
intrinsic replacement. Public function property hooks and function prototype
changes are supported observations to test, not automatically excluded by this
intrinsics assumption. Function source text and diagnostic stack locations are
not stable compiler-output promises.

## Prospective controls

First freeze unchanged and transformed modules plus exact changed-function text
and hashes. Reject any derivation that changes more than `invokeExact`. Run the
existing 146 ordinary/prototype observations, 72 scalar oracle executions, nine
entry/reentrancy cases, 121 scalar points, selected-arm copy-boundary suite and
saved-callback identity/shape controls. Use corrected generic/reference output
when a previous prebinding transformation is relevant.

Add focused paired public-observation cases for registered callbacks:

1. Own `call` data property containing `exactCall`; own getter returning it;
   ordinary alternate prototype with that property; prototype getter; and Proxy
   prototype lookup returning it. Record every getter/trap and raw reentrant
   callback before the outer invocation begins.
2. A getter returning the native method after mutating G, scalar helper code,
   scalar inputs, or vector length. An environment getter that changes `.call`
   after it was read, changes G, invokes a nested exact call, performs a raw call
   on the same vector, or throws. The whole-closure guard must still fail when
   relevant, and raw reentrant calls must remain unprivileged.
3. Custom ordinary/bound/Proxy methods that record receiver identity, argument
   vector identity and return a raw callback result. They must see the original
   receiver and get no eager-entry permission. Include a getter on the custom
   method's own `.call` to prove it is never consulted.
4. Noncallable method values `null`, `undefined`, numbers, symbols and ordinary
   objects; throwing method getters; throwing environment getters; revoked
   callable Proxies; class constructors; and a callable hook throwing its own
   TypeError. Compare exception class, raw message and event order. In particular,
   environment effects precede rejection of a captured noncallable method.
5. The same getter/receiver cases on a registered matcher1p callback, including
   projected field vectors with changing/throwing `slice` and `length`, exact
   versus overapplied outer calls, and raw return shape. This checks the other
   consumer of exact-entry permission rather than only scalar loops.

Private diagnostic entry flags may change from false to true when an accessor
returns the actual native method; that is the intended new sufficient proof.
The gate is equality of public values, raw-call behavior, exceptions and property
observation order, not equality of this private conservative-policy flag.

Keep instrumented entry/reflection counts separate from timing. If all controls
pass, freeze screen and long-warm confirmation for the unchanged scalar helper
and one original workload with frequent registered selected-arm entries (such as
the existing edit-distance fixture). Use the exclusive CPU3 slot. A useful result
must survive the usual drift checks and justify maintaining the custom-method
fallback. No production change is implied by this plan.
