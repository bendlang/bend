# Remove the allocation for exact-entry permission

Prospective isolated runtime ablation, after checked attempt12. This changes
neither the permission policy nor scalar-region admission. It does not include
the separate actual-call-value experiment, bulk descriptor reads or guard
hoisting. No production source edit is authorized by this experiment.

Currently each registered exact invocation allocates a private
`{code,args,used:false}` record. Replace that record with three private module
slots: current code, current argument vector and consumed flag. Before entry,
save the previous three values in ordinary local variables, install the new
values, and restore them in the same `finally` block. The empty state uses a null
code; every registered wrapper supplies an actual function, so it cannot match
that sentinel.

Keep `invokeExact`'s existing registration/prototype/call-descriptor checks and
all failure branches. Read `code.call` and then `f.env` in their original place;
capture the prior state only after both reads. Keep the existing Reflect.apply
call, argument vector, wrapper identity, callback kind and return behavior.
The only removed allocation is the permission record; the Reflect.apply vector
and ordinary callback/argument allocations remain.

The key proof is that only the current token can mutate. `enterExact` compares
private ordinary fields synchronously and marks a matching token consumed before
calling the inner body or reading any user argument. A nested exact call
suspends the prior token and installs another one. While the nested token is
current, no code can consume the suspended one: both code and vector must match
the current state. The private record never escapes. Its saved consumed bit
therefore cannot change during suspension, and restoring a saved scalar bit is
equivalent to restoring the old record reference. Getter effects before token
installation and exceptions during a callback retain their original order.

Derive paired files from immutable actual12 checked emissions: the maintained
scalar helper fixture and original edit distance. Verify their checked receipts
and compiler/runtime identities. Change only the state declaration, enterExact
and the installation/restoration statements in invokeExact; assert all other
bytes remain unchanged. Attach the existing complete-four-array row adapter to
both edit-distance variants without changing its arithmetic or row/cell calls.
Prepare separate diagnostic exports for direct runtime controls, never timed.

Before timing require the maintained 146 ordered ABI/prototype observations,
72 scalar checks and nine emitted entry cases, the fixture oracle family and row
full-state points. Add independently authored direct paired controls for nested
same/different-code entry, same-vector slot reentry, environment reentry, raw and
forged permission, caught/uncaught throws, partial/overapplication, custom call
hooks, and deferred bounce/build execution. Record flags for the diagnostic
callbacks as well as complete values, errors and event traces: this experiment
must preserve the private permission decisions too.

Freeze hashes, complete outputs and configs before the exclusive timing slot.
Use actual12's scalar helper `[128,524800]` and the cheap edit row `[32,17]` as
separate points. Do not run the full edit-distance benchmark through a
microbenchmark's minimum-call floor. Standard host intrinsics, including WeakSet
and Reflect.apply, remain the existing scope. No speed estimate is assumed; a
negative result leaves the present runtime unchanged.
