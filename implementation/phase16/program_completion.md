# Complete programs after ordinary and live-instance checking

The frozen baseline refused incomplete programs before validating live template
instances. This hid the actual unfilled reference in
`check/axiom_runtime_capture.bend` and affine-use errors in instances whenever a
source TODO also existed. Open laws and source holes were also counted in two
places, so a program containing one of each reported only one TODO.

`program-completion-source-01` follows the root's
[program-completion design](../../design/phase16/program-completion.md). Six
existing declaration workers carry an explicit `complete` Boolean. Existing
public checker and exact-prefix diagnostic APIs pass true and retain their
contract. The new `check_program_diagnostic(book, validated, origins)` passes
false through the same authoritative checker, preserves its failure, runs the
existing specializer, then calls the existing source-book TODO counter once.
Successful results contain the materialized book. Specializer failures retain
their original diagnostic and trace.

Checker-result ABI2 gives this orchestration to Bend. The host consumes the
returned materialized book and skips its old TODO/specialization stages. ABI0
and ABI1 retain their existing paths. Unknown capabilities and an advertised
ABI2 without its callable entry are explicitly refused. Component users may
continue calling the old APIs directly; a component advertising2 without the
program entry cannot be used as a whole-program host compiler.

The three-file delta from `wave7-source-01/project` is **28 Bend lines and1,711
bytes**, plus **six host lines and712 bytes**. The source manifest and exact
patches are under `program-completion-source-01`. No kernel, specialization,
runtime, cache schema or production source was edited.

`program-completion-checked-01` passes genuine checked bootstrap, derived B1,
unchanged v5 lineage and36 maintained focused controls, retaining their two
existing diagnostic differences. The corrected paired suite in
`program-completion-validation-01` has **22/23 exact observations**, up from18/23
in `program-completion-baseline-02`. The four gains are the existing runtime
capture fixture, TODOs before and after an invalid live instance, and the mixed
open-law/TODO count. Primitive status/phase results remain unchanged; no prior
exact match was lost. Worker health is audited separately from process exit.

The remaining `same-body-known-gap` is preserved: TypeScript checks an invalid
live instance before a later ordinary error inside that body, while this
whole-program staging still reports the ordinary error first. This patch does
not implement term-level chronological checking and does not claim to solve it.

The first root baseline used bare `?` in four new fixtures. Those rows fail
parsing upstream and did not test completion. All original evidence remains;
controls02 use `?TODO`, and every other baseline row was inspected for the
intended failure phase. The first direct-control runner also selected the module
namespace instead of its default API and stopped before semantic probes. Its
consumed runner, instrumented copy and failure record remain in direct01; the
corrected runner uses a new direct02 directory.

`program-completion-direct-02` passes **8/8 independent scenarios**. Each compares
legacy full DResult values, exact-prefix results, invalid-prefix fallback and
check_book error projections with wave7. Program results agree with full and
invalid-prefix calls. Ordinary failures preserve the old DResult; success books
match the existing specializer independently, including a materialized app~0.
Instrumented calls prove specialization runs once only after ordinary success,
and TODO counting runs once only after specialization success. No TODO pass
runs for either kind of semantic failure. The scenarios include open laws,
source holes, fills, valid/invalid instances and the retained same-body boundary.

`program-completion-audit-01.json` binds artifact identities, all paired primitive
axes, four gains, no losses, direct controls and zero worker failures/timeouts.
All owned compiler/control jobs are closed. Parent independently owns ABI routing
mocks and final integration gates. These local results make no timing or complete
chronology claim.

The parent's independent `program-completion-host-01` passes **10/10 actual
frozen-host routing controls**: absent/explicitABI0, historicalABI1, ABI2
success/failure, unknown3/-1/string2 and advertised2 without its entry. ABI2
skips the legacy checker/TODO/specializer stages; historical routes retain them.
That independent report is included in the final audit identity binding.
