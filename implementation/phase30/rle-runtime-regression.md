# Static diagnosis of checked16's RLE regression

The final16 same-window RLE point reports0.0493763ms versus Phase29's0.0447673ms,
10.30% more time, with disjoint sample ranges and mostly at most1.4% half drift.
This residual regression remains visible. The comparison calls `main.out()` on
the original six-element input and requires11; it does not time IO printing.
This note records static source/diff inspection during the clean matrix. No
diagnostic program, AST auditor, counter or new timing was executed.

The saved checked-emission receipts bind the same source SHA
`ce4083dab9a8022b2c8867a30802113735917229341cecb8ce18ff9ac2e33989`,
same Base and identical typed-driver bytes. The emitted modules are:

- Phase29: `selfhost/build/phase29/transfer-04/test-rle-roundtrip/candidate.mjs`,
  SHA `ad8657b5b37a6a1fc1cf2054b37cd19a9626e0c26737887a2000bae08d05e483`.
- Checked16: `selfhost/build/phase30/transfer-16/test-rle-roundtrip/candidate.mjs`,
  SHA `2ac708214d34a4a77058a4b54901a50be550e6e94df481335f10867e836accda`.

These identities are read from their retained receipts; any future derivation
must rehash the files and freeze its exact consumed tool and input bytes.

## What changed and what did not

**There is no guarded private region in this module.** No emitted definition
calls `scalarGuard` or registers an `exactCode` callback. Only `bu` acquires a
definition-time `scalarCapture`; that preserves its public descriptor and runs
before timed invocations. No empty or tiny scalar region is paying a guard on
each RLE call. The private scalar/terminal/tree/Let optimizations do not admit
these recursive List/Tuple functions.

Static comparison of corresponding emitted definitions shows these changes:

| Change | Sites/scope | Possible runtime consequence |
|---|---|---|
| Non-tail `call` becomes `callOwned` | Same original argument expressions throughout emitted bodies | Removes a fresh-vector copy; also changes the apply branch and potential JIT specialization. Earlier gains elsewhere do not prove a gain on this point. |
| Retire selected-arm prebinding | `lconcat`, `lrepeat`, `lrevp.go`, `expand`, `digest.go`; also `U32.show.go`, outside the timed `main.out` graph | Replaces preconstructed partial arm descriptors with original matcher→jump→apply behavior. This can reintroduce generic application work; it also restores the reviewed public scheduling contract. |
| Generic exact dispatch enters `invokeExact` | Every exact application in the common runtime | Reads the code once and checks `exactCodes.has(code)`. The module's registry remains empty because there are no registration call sites. |
| Definition-time snapshot of `bu` | One ordinary Bool helper | Initialization work only; no invocation-time guard. |

The algorithm's arithmetic, List/Tuple construction, recursive calls, matches,
and input are otherwise retained. No new countdown, F32 change, private tree,
helper rewrite or terminal-record construction appears. This is a syntax-level
inventory, not an executed whole-AST equality proof or a dynamic operation count.

## Smallest next discriminator

On an immutable copy of the checked16 RLE module, replace only the complete
`invokeExact` body with:

```js
function invokeExact(f, all) {
  const code = f.code;
  return code.call(f.env, all);
}
```

Keep the function-call boundary, method lookup before environment lookup,
`code.call` error selector, owned vectors, matchers and every emitted body.
The source-level registration audit must assert that `exactCode` occurs only
as its runtime declaration and that the private registry cannot receive entries.
Under the existing standard-intrinsic scope, the removed WeakSet predicate is
therefore always false. Imported/replaced public descriptors are still generic;
an independently registered callback from another module is absent from this
module's private registry. No snapshot, cache or first-use authorization is added.

Before timing, verify the complete inverse edit and untouched generated suffix,
original result11, independent short List/run-boundary values, descriptor and
code.call/env getter order, saved/raw/oversaturated callbacks, and the accepted
same-runtime error observations. Keep a separate unchanged16 module. A small
clean comparison can then distinguish the cost of the empty-registry check from
the remaining changed matcher/vector shapes. It cannot establish a general
runtime gain for modules containing registered workers.

If the dispatch-only variant does not explain the loss, a separate callOwned→call
diagnostic can isolate vector ownership/JIT shape. The removed historical arm
prebinding is a third mechanism, but restoring that implementation is **not** a
correctness-preserving fix: inherited raw/oversaturation scheduling witnesses
already reject it. Any later safe arm specialization must independently preserve
those witnesses and demonstrate a benefit over the simpler checked16 path.
Do not combine interventions or hide this regression in an aggregate gain.

The later [P30-030 acquisition](registration-dispatch.md) executes the complete
binding audit and scoped correctness gates. It proves zero registrations for
RLE and H, with H's quoted code-generator strings excluded. Performance remains
a separately controlled question; the initial static findings above are retained.
