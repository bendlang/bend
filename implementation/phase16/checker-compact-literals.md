# Compact literals: checked representation checkpoint

The isolated compact-literal compiler loads the same compiler source into
**152,620 terms instead of2,171,045:92.97% fewer**. The authoritative checker
accepts that source. This is structural evidence, not an end-to-end speed result.
The source adds94physical lines and11definitions, with no new datatype. It adds
one sibling constructor to KTerm and replaces the Nat-only representation with
an explicit interpreted literal value.

The candidate remains unselected. Focused semantic/backend gates pass, but the
old incidental memo-key size guard is demonstrably incompatible with compact
values. A canonical pinned JSON encoder and explicit optional Lambda quantity
presence are the next justified stage; they must close before integration.

## Mechanism

The preceding [census](checker-compact-literal-census.md) found3,559 source strings
containing27,244 characters. Together with integer/character literals they caused
29,487 U32 builders and973,071 word-builder entries. Ordinary source strings had
become millions of Word/Bool constructor nodes before scoping and freshening.

`KLiteral{kind,number,text,originBegin,originEnd}` stores Nat/U32/F32 bits/String.
The ordinary eight-field KTerm is unchanged. Structural traversal, substitution,
freshening, alias/path qualification, pattern origins and specialization shifts
preserve a closed literal leaf. Semantic consumers share one first-step helper:
Nat and String expose one constructor layer; U32/F32 expose one bounded word.
Matching, comparison, descent, inference, annotation and emitted code use those
existing boundaries. Trusted matching Base goals check without expansion.
Ordinary user datatypes retain normal constructor checking and layout.

Valid decoded strings stay compact. Invalid Unicode scalar escapes preserve the
pinned constructor-chain fallback; character numeric payloads remain compact.
Prettyprinting uses existing quoting/sugar. JS/native emission consumes literal
values through its existing provenance checks. The now-unused eager f_word
builder is removed. Literal versus written-constructor identity survives for memo
keys; numeric spelling alone is not identity.

During the audit, a separate [constructor-note bug](checker-constructor-note.md)
was isolated and checked: the datatype suggestion must require absence of a
constructor family. This fixes the false F32 note independently of literals.

## Frozen candidate and gates

The [design](../../design/phase16/checker-compact-literals.md) predates the
implementation. Checked source05 is
`selfhost/build/phase16/checker-literal-source-05/project`; its genuine checked B1
and guarded derivative are in `checker-literal-build-05`. Every attempt remains.

| Gate | Result | Evidence under selfhost/build/phase16 |
|---|---:|---|
| Representation-only transport |48/48|checker-literal-transport-01|
| Maintained workflow selection |36pass;2inherited exact gaps|checker-literal-build-05/validation-001|
| Literal-focused pinned corpus |176/176exact|checker-literal-focus-05|
| Direct pinned literal/step/pretty/compare/Unicode/bit controls |143/143|checker-literal-direct-01|
| Host payload/cache/capability/positional transport controls |31/31|checker-literal-host-01|
| Maintained JS/native/interpreter/check selection |41/41exact|checker-literal-backend-07|
| Same-source public loading and authoritative checking |pass|checker-literal-compact-census-02|

The literal corpus includes datatype shadowing, literal unfolding and comparison,
match/descent, malformed literals, long strings and both existing template growth
fixtures. The backend retry uses exactly the frozen Clang16 environment from the
root's wave6 gate. The direct signed-zero controls retain distinct F32 bit values;
pinned literal values are bits. The source language uses F32.neg, not a unary
negative float token. This does not claim arbitrary malformed direct terms are
well typed, general stack safety, full frontend conformance or a new fixed point.

## Comparable whole-source counts

Both sides use source SHA
`f90cfb97987b4a0f13311ac368eb179c2f77439ae9650cec200f12df10220380`,
the actual frozen compiler source from the earlier stage matrix. The baseline is
`checker-base-prefix-serial-01`, full arm, after validation and freshening. The
candidate's public seeded loader runs that same successful validation/freshening
boundary. Both have2,894top-level declarations and3,015total KDef objects including
constructors, with150,871located terms. These are different counts, not changed
corpus sizes. The raw baseline before freshening had2,171,037terms; the comparable
final count is2,171,045.

| Final loaded book | Baseline | Compact candidate | Reduction |
|---|---:|---:|---:|
| Unique terms |2,171,045|152,620|92.970%|
| Unique object nodes |8,648,663|575,787|93.342%|
| Full linked-list JSON bytes |337,202,666|25,324,867|92.490%|

Both byte counts use the same exact named-field Con/Nil JSON framing. The initial
compact-census01 used per-definition JSON plus newline; its25,249,612-byte result
must not be compared with the baseline full-list stream. Census02 corrects the
measurement contract without changing source or compiler. Distinct output hashes
are expected because the term representation changed. Full input hashes and
counts are in the adjacent JSON report. Operational RSS and elapsed probe values
are retained in raw reports but are not controlled comparative measurements.

## Protocol and production handoff

The tested prototype advertises literal ABI1 alongside unchanged source-range
ABI3 and uses compiler-bound Base cachev5. Malformed kinds, unsigned numeric/text
payloads, lone-surrogate compact strings, stale ranges/caches and unknown
capabilities are rejected. Historical absent-capability APIs and positional
literal round trips have direct controls.

The upcoming Lambda union replaces this uninstalled literal-only capability with
one compiler_term_abi1 and cachev6. The representation owner owns that consolidated
transport. Frozen literal05 evidence remains unchanged.

`checker-literal-handoff-01/{combined.patch,manifest.json,project}` records every
parent-relative delta:21Bend modules and2host/workflow files. Every Bend byte agrees
with checked05. The handoff removes two probe-only export lists; that host-only
change is deliberately unbuilt until root integration. No live image is installed.
Source changes versus wave6 are15,759→15,853physical lines,
13,436→13,517nonblank lines,544,617→550,244bytes,1,585→1,596definitions,
776laws and63types unchanged across59modules.

## Memo boundary findings and next stage

`checker-literal-memo-02` preserves all eight real instance controls. Seven agree,
including repeated U32, equivalent string escapes and the saved U32 literal versus
written-constructor counterexample. Repeated F32.neg(0.0) still produces two local
instances where TypeScript produces one: the inherited key retains Ref token IDs.
Ten of20size boundary observations disagree because the short local encoding
omits JSON overhead/escaping and counts scalars instead of UTF16 units. Current
keys therefore remain unselected even though both existing growth fixtures pass.

The representation owner independently proves another missing fact:
`&x:Type -> Type` and `Exists(Type, x => Type)` have identical current Lambda
nodes but pinned keys differ184versus201UTF16 units because quantity presence is
optional. The approved next stage preserves that fact only on Lambda nodes and
uses [one exact JSON encoding](../../design/phase16/checker-canonical-memo-json.md)
for both memo identity and the unchanged32768guard. There is no threshold tuning,
padding, source-text guessing or alpha-renaming assumption. Full integration,
Phase12's saved resource history and controlled whole-host timing remain required.

## Retained unsuccessful attempts

Source02 was rejected by static review before building: a preparation wrapper
placed three closing parentheses after following law declarations. Source03
corrected only those delimiters. Source04 preparation requested nonexistent
probe export g_normalize and stopped before building; source05 corrected the
probe name. Neither is a compiler correctness result.

Backend05 retained12native unsupported observations because the default
environment lacked Clang;29other rows were exact. Backend06 stopped in setup
because a full identity verifier expected canonicalPath in a historical record
that supplied only file/hash. Tool02 validates the fields actually supplied;
backend07 closes all41 with the exact pinned environment.

Memo01 stopped after three successful cases on the invalid unary-negative source
control. Its catch expected Error.stack and omitted the structured Bend error;
fresh controls use the accepted F32.neg form and the tool retains structured
failures. The preliminary fixtures and report remain visible. None of these
failures is silently folded into the successful gates.
