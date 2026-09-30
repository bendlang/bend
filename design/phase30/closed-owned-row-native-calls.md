# Direct native Array calls inside the already closed row region

The first owned-row ladder retains exactly four allocations, four Array.get
operations per cell and four Array.set operations per cell plus initialization.
At size 32, its final variant still executes 794 generic applications. The short
screen favors it, but substantial warmup drift prevents a settled speed claim.
This follow-up isolates native descriptor application inside the same previously
checked region; it does not change storage, projection, copying or ownership.

Freeze one additional generated-JavaScript variant, derived from the exact
`prototype-owned-01/private_row.mjs` bytes. Keep the same scalar probe, immediate
U32 input checks, size-at-most-64 bound, exact-entry permission and sixteen
original definition-time snapshots. Keep the original
generic probe expression and every public definition unchanged. Unknown,
replaced or mutated native descriptors must fail the existing guard before any
private work; snapshots remain at module initialization, never first use.

Inside the admitted branch and private cell exact-field bodies only, replace
complete native Array.new/get/set applications with private direct helpers.
Those helpers use the exact current native method expressions, including the
erased type slot and source argument order:

```
(_t, d, v) => arrayfill(v, d, '^')
(_t, a, i) => arrayget(a, i)
(_t, a, i, v) => arrayset(a, i, v)
```

Keep `arrayfill`, `arraydata`, `arrayget` and `arrayset` unchanged, including
validation, modulo indexing, handle identity and the original two-element
Array.get result. Non-tail native applications still force the returned value.
The tail Array.set remains inside the original Dp field thunk, with the same
saved aliases and full region forcing; the direct helper runs only when that
field is demanded. No setter moves into an earlier field or before build/force.
This private eager result is admitted only because the full local graph is
forced before exact callback return. Raw, forged, constructed and overapplied
entry keeps the original delayed public expression.

Keep `gen` and `init` entirely generic, including their native Array.set
applications. Their setup cost remains a fixed residual in this experiment.
This restriction was clarified by the parent before derivation or execution;
the earlier idea of private copies with only native-call substitution is
deferred to a separate experiment if warranted. Do not introduce a second loop
rewrite, private PRNG, Array.get result
flattening, direct field access, mutable scalar row state or a per-call guard.
The original zero-row swap still runs through the public row arm.

Before timing, run the same 28 independently calculated complete-array points,
alias/freshness/zero-swap observations, all retained raw/copy/hook and
descriptor-mutation controls, and the independent deferred-result suite. Add
explicit mutations of each native descriptor before first probe use, including
in-place code mutation, then compare the public fallback traces. Verify the
baseline and new variant keep identical public row, cell, gen, init and native
definitions and full returned handle sharing. Run separate diagnostic copies
to show unchanged allocation/get/set/build/ctor counts and one region guard,
with only native descriptor application removed. Diagnostic modules never
enter timing.

Freeze a new paired size-32/seed-17 screen and confirmation configuration with
the original generic baseline, previous private-row variant, new native-call
variant and pinned TypeScript output. Preserve all earlier receipts. Measure
only after independent semantic review and a new exclusive timing grant. Stop
at any unresolved ownership, forcing or snapshot counterexample; no production
implementation follows from this disposable experiment alone.

Retaining non-tail force is a semantic requirement. Array.get returns a plain
Tuple array that must be forced at the original demand point. Independent
static review identified an additional closure boundary before derivation:
Array.prototype marker getters can mutate G while the region is running. The
original owned-row ladder assumed standard Array intrinsics and its guard did
not reject these hooks. Pure logging-hook equality would not establish closure
stability.

The new derivative therefore adds one outer eligibility check, alongside the
existing full closure guard: Array.prototype must retain its original Object
prototype parent and have no own request/bounce/build/code descriptor. Any hook
sends the entire probe through its unchanged generic fallback. No native call
gets an additional guard. Other standard-intrinsic assumptions remain explicit
and unchanged. Retain an executable mutating-marker witness for the earlier
limited-domain artifact, and compare the new candidate to the generic baseline
for logging, throw and mutation hooks. This prospective strengthening occurs
before deriving or executing the new variant; it does not rewrite old evidence.
