# Parser checkpoint oracle and rejected-frame inventory

No compiler source was changed. The corrected read-only suite uses frozen
wave8-build-01 and pinned TypeScript b2111cf, with22 new negative controls, two
positive controls and the maintained monad fixture represented as25 fixtures in
50 parse/check observations. The precise inventory is controls03/manifest.json;
this selected suite is not a full-corpus conformance metric.

`parser-checkpoint-baseline-03` records **16/50 exact observations**. The34
remaining differences separate into30 chronology observations (15 fixtures), two
span observations for an unbound empty call, and two actual acceptance
observations for a bound empty call. Every reference acceptance/phase oracle is
valid. Each worker completed50 requests with zero failures or timeouts. The
candidate selected gate correctly fails for the accepted bound-empty-call
witness; the final audit passes only as an oracle/evidence audit, not as a
compiler-candidate validation.

The chronological rule is broader than the original do example. Computed
applications, Type, lambdas, constructor arity and qualified patterns must be
validated after their RHS and before their continuation. A later malformed
continuation currently wins in all of these cases. Parameter, lambda, local,
parallel, match-field, dependent-binder, module-alias and do contexts reproduce
the problem. Conversely, bad RHS syntax, valid patterns with bad continuation,
and a bad case body before an invalid global match head already choose the
correct error. These exact controls must remain protected.

The alias controls demonstrate why lexical context is mandatory for rendering:
TypeScript reports `lib.id(x)` for the imported function but `M.id(x)` when that
spelling names a local parameter. A module-only FParseScope cannot distinguish
these. The [frame inventory](../../design/phase16/parser_failure_frames.md) also
identifies less obvious boundaries: earlier telescope cells, law/refinement
binders and rewrite-motive bindings. TypeScript closes rewrite-motive bindings
before parsing the rewrite body.

The empty-call witness corrected an initial hypothesis. At `(` TypeScript forces
only an unbound Var's fallback global Ref; an already-bound variable stays Var.
Thus unbound `x() = ...` is rejected (Bend's retained difference is only its wider
span), while `def use(x:Nat) -> Nat: x() = {0n:Nat}; x` is accepted upstream and
rejected by Bend during parsing. A raw Call tag cannot establish pattern
invalidity. This acceptance issue is separate from error chronology.

Controls01 mistakenly declared an unbound empty call positive, and one grouped
RHS case had insufficient indentation to test the intended case-body failure.
Controls02 corrected both and retained a new bound-call witness. Its two positive
controls then exposed the unrelated need to annotate local Nat RHS values;
controls03 supplies `{0n:Nat}`. All previous fixtures and failed reports remain.
No failing oracle was weakened to fit Bend's behavior.

Recommended next review: retain the context owner's completed-prefix correction
for framed_cell_capture as its own stage. Before implementing the monad/general
checkpoint correction, choose between an explicit rejected-path frame protocol
and contextual term parsing. An error-only protocol must preserve outer pattern
eligibility and prior inner errors, not just names. Blindly flattening unfinished
Local/Row trees is invalid: it would move enclosing match-head errors ahead of
case-body syntax errors. The static census reaches104 callers of the relevant
checkpoints, showing that full contextual term parsing is a substantial interface
change. No claim of a small complete transport is made before its frame proof.

Evidence: `parser-checkpoint-audit-03.json`, `parser-checkpoint-baseline-03`,
`parser-checkpoint-controls-03` and `parser-chronology-census-01.json`, all under
selfhost/build/phase16. All owned probe processes are closed. No performance claim
or implementation gain follows from this read-only investigation.
