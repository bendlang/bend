# Stage1: checked names and state probe

Prospective refinement of [the contextual slice](contextual-parser-slice.md).
Root authorizes only seed/control preparation and this bounded names/state
prototype, with a review pause above 150 added production lines. Parent is the
immutable Phase18 cursor-source-02 project / cursor-build-01 API5d19edf5.
No body-owner migration or public parser routing is part of Stage1.

Use one explicitly exported experimental Bend root `f_context_probe(input,seed)`.
The only host delta adds that export to the isolated checked bootstrap. A new
contextual source module is added to the isolated module manifest. The root has
a fixed diagnostic protocol below; it is not an instruction interpreter. It
does not claim to implement `f_context_body`, does not emit FContextCore, and
cannot be called by ordinary production parse/load APIs.

Input must be FInput with the existing **raw** FCursorContext constructor.
Supplying an already contextual cursor is an explicit probe-contract refusal,
not a nested initialization that silently loses scope. Seed provides the shared
FParseScope, parameters in telescope order, and an exact next ID. The probe
reverses parameters for newest-first lexical lookup. It returns contextual
cursors; it does not claim to restore the caller's raw context.

The first semantic payload is one ordinary valid name token. The root consumes
that token with the existing cursor helper and runs the actual prospective name
resolver on its located Ref. It returns a distinct probe refusal on malformed
or currently unsupported input. Compound syntax, plus/marked syntax, and body
syntax are explicitly unsupported in Stage1, and cannot count as conformance
passes. The eventual marked syntax view remains the existing FUnboundVar
sentinel; Stage1 must not approximate it using a U32 negative ID.

The fixed protocol exposes four observations:

1. Resolve the name in the seeded environment. Bound lookup skips module/alias
   resolution and consumes no fresh ID. An unbound ordinary name allocates one
   ID and returns FName with an explicit Var syntax child and canonical Ref
   fallback. An unbound dotted name remains a Ref alternative and consumes no
   fresh ID. No ADT materialization or value-only refusal is allowed here.
2. Invoke the low-level open operation on that written name; this allocates one
   fresh identity and pushes it unless the name is `_`. Resolve the same origin
   again, recording the new binding. This is `parse_open`, **not** proof that
   the spelling passed lambda or pattern eligibility.
3. Restore the original seeded lexical stack while retaining the new counter;
   resolve the name again. This exposes accidental fresh-counter rewind and
   incorrect shadow restoration.
4. Restore the original token list while retaining the last returned context.
   This exposes the token-only rewind primitive. Actual typed-let wiring comes
   later and may use it only after a successful annotation with no assignment;
   Error/Unsupported results are propagated without any rewind.

The probe result carries the first lookup, opened binder, inner lookup, closed
lookup and rewound cursor as explicit fields. Error at any resolution stage
short-circuits later steps and returns a separate probe Error result. Source
range and parser next are observable in those actual FParsed/FInput values;
there is no second independently mutable status or fresh counter.

New FCursorContext variant `FContextual{scope,env,next}` is the mode authority.
Name lookup reuses f_env; canonical selection reuses f_alias, f_qual_name,
f_declared and the existing alias ambiguity/error constructor. Lexical lookup
comes first. The final near/far choice matches pinned parse_reso, not the legacy
post-module f_resolve_name helper (which has a different input contract).

Freeze controls before source: empty/unbound names, existing global names,
zero-arity datatype, nonzero-arity family, constructor spelling, same-name
parameters, underscore, namespace near/far/missing names, canonical alias and
ambiguity, a dotted local shadowing that ambiguity, and independent sibling
seeds. Retain malformed/marked/compound-input Unsupported observations separately.
Pin header seeds from actual TypeScript parse_tele events; do not derive expected
IDs using candidate fc_start or token coordinates. Direct TypeScript parse_var,
parse_open and parse_close form the independent state oracle. Its outputs are
test data only; the candidate never calls TypeScript.

The probe is genuinely checked and emitted from Bend. No injected JavaScript
implements contextual semantics. Initial gates are checked B1/maintained36,
direct protocol equality including every counter/stack/cursor/range, and the
unchanged public raw/whole-book cursor controls. Record exact net lines and
concepts before requesting the next subwave. Broader saved196, semantic16/114,
and monad2 remain required by the main plan before a contextual-body claim;
this isolated primitive probe does not fulfill them.
