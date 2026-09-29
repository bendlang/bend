# Phase16: keep literal values compact until a semantic consumer needs a head

## Measured cause and target

The unchanged wave4 compiler source elaborates from94,044 parsed KTerms into
2,171,037 raw core terms. The operation census binds the exact source/API/cache
and reproduces the earlier total. String-shaped subtrees account for1,868,327
terms (86.06%), U32-shaped subtrees170,690 (7.86%), and Char-shaped subtrees6,075.
These structural groups include explicit constructor syntax; they are not a
claim that every such node came from a written literal.

The actual builders separately establish the cause:3,559 strings decode27,244
characters. Together with2,153 U32 literals and90 character literals they invoke
f_u3229,487 times, and f_word exactly29,487×33 times. String literal construction
alone produces1,856,151 nodes before later substitution/freshening copies. Nat
already has a compact special case. Removing the checked Base prefix would save
only1.3244% of freshening visits; a new Base-cache protocol is deferred.

Target one general literal concept, preserving written literal identity and its
closed interpreted value through scoping, substitution, freshening and checking.
Normal forms may expose constructor heads only where semantics require them.
No TypeScript fallback, source-text guessing, origin-bit encoding, or payload in
binder IDs/quantities. Ordinary KTerms gain no field.

## Representation and boundaries

Add a sibling constructor to the existing KTerm datatype:

`KLiteral{kind: String, number: U32, text: String, originBegin: U32, originEnd: U32}`

The kind is Nat/U32/F32/String. Numeric constructors carry their U32 value (F32
bits) and empty text; strings carry decoded text and number0. Small constructors
establish that invariant, and the host ABI/cache validator rejects malformed
payloads. The payload is explicit rather than hidden in existing KTerm fields.
The parser's raw Literal token remains separate until normal literal validation
and decoding have succeeded. Original spelling is not a memo key: equivalent
numeric spellings have one interpreted value, while a literal stays distinct
from an explicitly written constructor tree.

Generic projections expose a closed leaf, and source projections preserve its
real begin/end. k_with_children, k_with_span, substitution, pattern origin
replacement and global freshening preserve its payload. Audit both explicit
KTerm matches and direct generic reconstructions; only auditing match statements
would miss sp_shift, alias/qualification/path traversals. Existing guarded
All/Lam/ADT reconstructions remain ordinary terms.

Generalize the existing compact-Nat boundaries, keeping one authoritative
checker and evaluator. The initial private transport stage may retain the old
LitNat adapter until all consumers and direct controls migrate; a second
independent evaluator or literal checker is prohibited.

- Checking accepts a literal without expansion only at the matching unremoved
  datatype supplied by trusted Base, following the pinned checker. An ordinary
  user datatype with the same spelling must use the normal checking path.
- Mismatched goals, inference errors, pattern analysis, match evaluation,
  structural comparison and descent expose the same first constructor step as
  pinned lit_step, preserving error order, locations and literal identity.
- Nat exposes Zero/Succ one layer; String exposes SNil/SCon with Chr{compact U32}
  and a compact tail. U32/F32 expose their bounded32-bit word only when demanded.
- Invalid Unicode scalar strings follow pinned lit_of's constructor-chain
  fallback; their character codes can still be compact U32. Keep escaped strings,
  astral scalars, surrogate code points and >U+10FFFF controls distinct.
- Prettyprinting and JS/native lowering consume the explicit value directly when
  the existing typed/native boundary permits it. General semantic fallback uses
  the shared first-step helper. A written constructor is never relabeled as a
  literal merely because its shape resembles one.

## Memo identity and remaining chronology

The earlier scoped-key candidate remains rejected. It fixed source-position IDs
but moved a growth refusal from grow~9 to grow~10, and U32 literal/constructor
identity had already been erased before it could serialize a key.

KLiteral restores that missing information. Keys must include the interpreted
kind/value and preserve literal-versus-constructor identity, source spans must
not participate, and the growth guard must follow the pinned logical JSON key
size rather than a newly shorter incidental encoding. Compare exact keys/lengths
on repeated values, distinct values, different text positions, nested templates,
quantity distinctions and both growth fixtures before promotion. The optional
written/generated Lam quantity distinction is a separate known serialization
question; do not silently claim literal metadata alone resolves it. No threshold
tuning, error-text arbitration or guessed source-order ranking is authorized.

## Stages and gates

1. Freeze the census/design, then create an isolated source from
   wave6-source-01/project. Add representation, projections and reconstruction
   support first. The existing successful paths must still work before the
   parser starts generating new variants. Use genuine checked B1 and direct
   immutable leaf/substitution/range controls.
2. Switch validated literal creation and generalize the existing compact-Nat
   consumer boundaries. Keep malformed-literal diagnostics exact. Test trusted
   Base versus user datatype shadowing, matching/reduction/descent, residual
   constructors, equality, erased/live uses, Unicode, F32 bit boundaries and
   repeated-equal literals at distinct source locations. Record every failed
   candidate; do not patch frozen attempts.
3. Close backend and memo contracts, including the rejected U32-vs-constructor
   witness, exact growth-key boundaries, primitive value distinctions and
   emitted JS/native behavior. Compare maintained controls and selected strict
   corpus diagnostics, including the F32 datatype-note case. Report inherited
   chronology gaps separately.
4. Only after focused correctness, compose with the root's other changes and run
   the full frontend/semantic/backend gates and the exact Phase12 history-sensitive
   long-string boundary. Whole-source timing uses a separate exclusive controlled
   window, same pinned TypeScript/source/environment, and complete host work.

No intermediate candidate is installed merely because a smaller gate passes.
Compiler bodies remain Bend; host changes are explicit ABI transport, validation
and versioning only. New variants require an advertised capability/format decision,
API-bound cache invalidation and historical-host/unknown-ABI controls. Document
that decision before accepting any new cache; never silently reinterpret old
positional data or accept a stale Base book.

## Expected cost and limits

This is one literal representation and shared demand helper replacing the current
Nat-only special case, not a new semantic subsystem. Initial source audit finds14
explicit KTerm matches in3 modules plus a small set of unguarded generic rebuilds.
Demand sites span the existing front/core/checker/pretty/backend modules. Expect
roughly150–300 net lines initially, with later consolidation removing duplicate
Nat-only branches; measure the actual result instead of treating this as a quota.

The census supports a large term/allocation reduction, potentially well over90%
of literal-construction nodes on this workload. A1.5–3× whole-request improvement
and several-fold lower peak memory are hypotheses for the controlled experiment,
not commitments: parsing and nonliteral checking remain, force frequency may
matter, and changed V8 histories can alter resource behavior. Source complexity,
strict conformance and end-to-end costs all gate the result.
