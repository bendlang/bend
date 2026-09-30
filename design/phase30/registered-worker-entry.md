# Separate worker lifetime from public callback lifetime

Prospective ablation after the actual07 scalar CPU profile. Many samples are
attributed to `enterExact` at its call to the worker. This may include inlined or
poorly attributed worker work, and does not establish the runtime cost of token
checks. Two distinct generated-code interventions can discriminate the cause.

First hoist the private `function(a,$entered)` implementation out of the
successor-arm factory, into its definition's existing private IIFE. Keep calling
`exactCode($worker)` for each selected successor arm. The public callback must
remain fresh: saved partials have independently mutable code functions. Keep
their anonymous one-argument ordinary-function shape, constructor behavior and
all existing token/argument reads. This changes only private implementation
lifetime and target stability. It is valid for the current top-level Nat-worker
rule, whose body captures only its private helper table/guards and module names,
not an earlier public lambda environment.

Second, independently fuse the public registered callback with its implementation.
Introduce private runtime operations to register a callback and consume its exact
entry permission. The generated successor factory creates a fresh anonymous
one-argument ordinary function, stores it in a private lexical variable, and
registers that same function. Its first instruction consumes permission using
its own identity and the argument vector, then executes the unchanged worker
body. Preserve the single-use record, installation after environment evaluation,
cleanup in finally, getter/call hooks, raw-call fallback and overapplication.
This removes a wrapper invocation and one private closure allocation, without
caching or sharing the public callback. Do not combine it with hoisting,
dictionary removal, input/descriptor-guard removal or fallback outlining yet.

Derive both exact module variants from actual07, asserting changed sites and
retaining all bytes. The fused variant's extra helpers are private experiment
code, not a new public API or a deployed runtime. Test all 121 scalar points,
the 146 ordinary/prototype observations, 72 scalar-oracle executions, nine
entry/reentrancy cases, callable shape, and two saved partials whose `.code.call`
hooks are mutated independently. Raw callers must not forge permission with
extra arguments or reuse a token during a vector getter.

Freeze screen/confirmation before timing and use the exclusive CPU3 slot.
Compare each intervention to unchanged07 independently. Only a passing, measured
winner is eligible for a small shared compiler/runtime implementation; keep
the current exact-entry semantic proof and existing fallback.
