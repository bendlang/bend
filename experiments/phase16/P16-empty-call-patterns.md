# P16: empty named calls in patterns

Status at freeze: prospective. Owner: parser lane, CPU3 correctness only.
Design: [empty call patterns](../../design/phase16/empty_call_patterns.md).
Parent `selfhost/build/phase16/wave9-source-01/project`; preserve source and
attempts under new `empty-call-pattern-*` names. Claim: the ordinary empty-call
bound/unbound distinction is sufficient to repair the saved positive acceptance
and unbound-width counterexamples without a new scope walk or changes to
nonempty/marked/offload validation. Falsify using exact paired outcomes,
independent lexical/nested controls, previous 50 chronology observations and
maintained checked-B1 controls. Root owns broad integration and timing.
Results belong in `implementation/phase16/empty_call_patterns.md`.
