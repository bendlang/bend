# Native array call boundaries

Agent-generated prospective Phase30 experiment, before output derivation or timing.
Scope: the existing edit-distance row fixture, exact Phase29 output and corrected
private02 output. No compiler/runtime source change is authorized by this experiment.

The remaining private-row generic applications include1,280Array.get and320Array.set
calls over ten32-cell rows. The existing runtime `arrayget`/`arrayset` functions
already implement array representation, modulo indexing, getters, mutation and
errors. Test removal of their descriptor/application boundary while retaining
those helper bodies and their argument evaluation order. Leave new/size and array
representation changes out of the first ablation.

Two generated-JavaScript-only variants per baseline are allowed:

- Fixed-runtime-native assumption: capture the original native descriptors but
  enter the existing helper directly. This is a mechanism upper-bound probe,
  explicitly ineligible for production if mutable native bindings remain observable.
- Guarded: evaluate the original `get(G,name)` before arguments, then validate the
  captured actual descriptor immediately before applying its already-evaluated
  arguments. Use own-property descriptors to reject accessors without invoking
  extra getters, and compare original code/arity/env/bound state. Unknown bindings,
  replacement, in-place mutation and erased-slot anomalies use the original call
  or tail-jump path. The guard cost is part of the clean measurement.

Capture the original runtime's Array.get/set identities after module initialization
and bind their code/arity/env/bound snapshots. Require the original ordinary empty
bound array and unchanged relevant descriptor attributes/fields. A first prototype
may conservatively fall back if any introspection is uncertain. Native source
identity is supplied by the original checked artifact; a production recognizer
would additionally validate the exact owner, native definition and full telescope.
Do not infer identity from the name alone.

Preserve `force` semantics: direct non-tail helper results still pass through
`force`, since a foreign array returned by set can itself expose observable bounce
or build properties. A tail site returns the helper result without an extra force,
so the surrounding trampoline keeps the original forcing boundary. Runtime array
helper code stays byte-identical. Preserve erased argument evaluation/position;
a malformed erased slot conservatively falls back in the guarded probe.

Boundaries: original28complete-state row oracles; foreign `.array` getters and
setters; backing-array index/length getters and modulo behavior; mutation order;
throwing operands/array access; returned array bounce/build getters; replacements
of native G entries; in-place descriptor code, arity, environment or bound changes;
partial public Array.get/set behavior. Mutating standard host builtin prototypes
is a separate runtime contract and is not silently proved by descriptor identity.
Ask the independent reviewer to challenge the guard and forcing boundary before
clean timing. Preserve failed probes and their exact bytes.

Derive both array-only and private-plus-array variants separately, retaining the
unmodified baseline/private variants. Freeze one six-variant point for row32,seed17:
old/private/old-array-fixed/old-array-guarded/private-array-fixed/private-array-guarded.
Use the existing screen and longer-warm protocols, serial rotated fresh CPU3
processes, exact complete-state checks, separate startup and first call, and no
instrumentation in timed modules. No TypeScript ratio is inferred from this
within-backend ablation; original upstream comparisons remain separate. Await the
lead's exclusive timing grant. Diagnostic helper/call counters run separately.

Evidence will decide whether direct native helpers are material, whether per-call
guards erase their benefit, and whether a closed pure region can amortize a guard.
No source transformation or speedup factor is promised in advance.
