# Exact runtime entry for private scalar loops

The runtime part of the [entry correction](../../design/phase30/scalar-region-entry-correction.md)
adds `natWorkerCode(inner)` and routes only exact saturation through `invokeExact`.
The anonymous, single-argument callback consumes a private record matching both
its function identity and argument-vector identity before calling `inner`. Raw
calls and same-vector reentry cannot forge or reuse permission. The record is
installed after environment evaluation and restored with `finally`; overapplication
keeps its original runtime path. Public descriptors receive no extra fields.

The registered ordinary-function path inspects callable metadata without getters,
resolves `.call` before the environment, and executes the captured callback using
`Reflect.apply`. Modified callable hooks, prototypes and unregistered callbacks
use generic invocation. The standard-host-intrinsics assumption is unchanged.

`inspection-nat-entry-01/report.json` contains 23 passing behavioral assertions:
exact/owned entry, raw and forged-extra-argument calls, overapplication, saved
partial completion, same-vector getter reentry, nested tokens, throwing callbacks
and environments, custom `.call` hooks/prototypes, code getter replacement,
unregistered Proxy observations and overapplication length ordering. Independent
static review found no semantic blocker within that scope.

The receipt deliberately remains **`pass: false`** because it also records an
unresolved observable error-message difference. When a registered callback's
`.call` getter returns `null`, both versions observe `call`, then `env`, and throw
`TypeError`. The original text is `f.code.call is not a function`; the captured
local expression produces `code.call is not a function`. No message normalization
was applied. This is not an exact diagnostic-equivalence pass and needs an explicit
scope decision or a preserving implementation before a stronger claim.

No generated-loop correctness or speed claim follows from these direct runtime
controls. Parent owns emitter integration, checked builds, reproduction of the
preexisting worker scheduling failures and clean performance comparisons.

Reproduce with a new output directory and the retained attempt03 core snapshot:

```sh
taskset -c 5 /home/ai/.nvm/versions/node/v24.18.0/bin/node \
  selfhost/tools/performance/phase30/inspect-nat-entry.mjs \
  selfhost/build/phase30/inspection-nat-entry-NEW \
  selfhost/build/phase30/attempt-03/snapshot/src/runtime/js/core.mjs
```

The receipt identifies both runtime sources and the test tool; it stores derived
runtime-only modules and the raw difference. Reproduction requires those ignored
snapshot bytes, which are not durably preserved by this report alone.

The subsequent selected-arm boundary correction reuses this mechanism and renames
the production helper to `exactCode`; the earlier receipt and consumed control
tool keep their original `natWorkerCode` identity. The maintained control tool
now targets `exactCode`. Its runtime behavior is also reviewed in the independent
prebinding-entry receipts; this rename does not retroactively alter the 23-control
observation above.

## Independent assessment of the diagnostic boundary

The independent reviewer agrees that accepting the documented identifier-only
TypeError text change is reasonable for malformed host descriptors. The
exception class, `.call`/environment evaluation order and user effects agree;
the changed word is a JavaScript engine rendering of an internal local expression,
not a Bend diagnostic or source-language result. Re-reading f.code to recover
the old expression spelling would introduce a more serious getter-order change.

This decision permits a correctness claim scoped to those behavioral boundaries,
not byte-for-byte equality of all engine-generated diagnostics. The raw failing
receipt remains unchanged and must stay visible. Explicit language errors and
user-thrown sentinel messages continue to require exact equality in controls.
