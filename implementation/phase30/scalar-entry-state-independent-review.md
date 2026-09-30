# Independent review of scalar exact-entry permission state

The analysis agent statically reviewed the prospective
[state design](../../design/phase30/scalar-exact-entry-state.md), the exact
`review-entry-state-derive.py` substitutions and paired direct controls. No
execution or timing was performed for this review. No semantic blocker was
found under the existing stable host-intrinsic contract.

The original token object is private and never returned, stored in an argument
or passed to user code. Its only mutator is `enterExact`, which reads the current
module token, compares code/vector identity and consumes it synchronously before
the inner callback can read any user argument. Those comparisons and ordinary
private-field reads cannot themselves invoke a hook.

A nested invocation replaces the current token. While that invocation is active,
every raw or registered entry sees its current code/vector/used state; none has a
reference through which to consume the suspended parent token. Restoring the
three saved scalar values therefore restores exactly the old object's state.
Same-code/same-vector nesting does not weaken this: entering the new invocation
consumes the new token, and later raw reentry sees its used bit. Upon return the
saved parent used bit is restored, rather than accidentally reopening permission.

The saved values are captured after the original `code.call` and environment
reads. Environment getter reentry may consume or replace the current prior
state before returning; both implementations snapshot the state after those
effects, at the same point. No accessor resolution, prototype guard, public
callback identity, raw/overapplication branch or method receiver changes. The
`finally` restoration covers both returned values and uncaught exceptions;
forcing a returned bounce/build occurs after restoration in both versions.

The null-code empty-state sentinel cannot match a wrapper's closed-over actual
function identity. Omitting the old explicit token-null check consequently does
not grant permission to raw calls. The three sequential private assignments
introduce no reentrant operation. Under standard `Reflect.apply`, no user code
runs between installing state and entering the registered ordinary wrapper.
Arbitrary replacement reflection intrinsics remain outside the declared scope.

The derivation changes only the declaration/consumer and installation/restoration
statements, and asserts an exact inverse transformation. Its focused controls
explicitly compare permission flags in addition to complete values, errors and
events for same/different-code nesting, same-vector getters, environment reentry,
raw/forged calls, call hooks, caught/uncaught throws and deferred work. Their
reported146 ABI,72 scalar,9 emitted-entry,121 oracle,28 row and17 state-scenario
observations belong to the owner's execution receipts, not this static review.
Timing remains an independent promotion gate.
