# Private helper binding form: static review

The declaration-to-const experiment has no identified semantic blocker in the
current emitted private graph. Static review covers `private-helper-binding.md`
and `private-binding-derive.py`. A separate completed audit below exercises the
frozen outputs; this report claims no timing result.

The region IIFE initializes private helper values, the guard-name array and
lazy public descriptors before returning. It invokes no private helper during
that initialization. A helper may refer to a later lexical declaration, because
the reference is read only after every helper binding has initialized. Current
region admission allows only saturated direct helper calls and scalar results;
no helper function value escapes. The emitted helper bodies use no `this`,
`arguments`, `super` or `new.target`, so ordinary versus arrow function metadata
has no program-visible consumer. Public callbacks remain untouched.

The derivative should retain its token-level private-name use assertion and
exact reconstruction of original bytes. Direct calls must exclude property,
value and constructor uses. A forward-reference control can use legally ordered
Bend definitions whose private JS helper emission places a caller before its
callee; it need not introduce unsupported live forward declarations in Bend
source. Explicitly assert that emitted ordering and execute the path. Raw
public descriptor and error/value/order controls remain required before timing.

`review-private-binding.py` subsequently audited the six frozen outputs in
`private-binding-{helper,whole}-01`, without editing those artifacts or their
configuration inputs. The passing receipt is `review-private-binding-01`.
Every private identifier is a declaration or a bare call, never a property,
constructor call or escaped value. Each call resolves to one declaration in its
generated definition IIFE. Separate counter copies instrument only calls from
an earlier helper body to a later helper binding.

All counters are zero immediately after module import, establishing that these
forward calls do not run during initialization. The original helper input
`[128,524800]` and whole-program input `[2,0]` produce exactly 128 and 887240761
across all declaration/constant-function/constant-arrow variants. Collectively
129 forward-reference edges execute in the six diagnostic runs. Counter copies
are excluded from timing. The parent's separate full public-boundary tests
remain distinct evidence.
