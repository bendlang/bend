# Independent review: local tuples and nonterminal records

Status: prospective admission gates, 2026-09-30. This review does not run builds,
compiler requests or timing. Root serializes all execution after the interruption
and suspected memory pressure. No compiler process may be launched by this review
without a separate root grant.

## Typed Array.get bridge

Review the actual Bend transformation and its generated bridge, separately from
the earlier saved-JavaScript derivative. Before admitting the actual candidate:

1. Require a completed private helper, a fully saturated call and an immediately
   consumed canonical Array.get<U32>. Its final argument must be the transformed
   JNative, and the complete helper body must unpack that final argument as the
   canonical two-field Array<U32>/U32 Sigma. Ordinary producers and noncanonical
   constructors retain their existing representation.
2. Preserve every earlier argument, erased slot, array and index evaluation in
   source order, once each. Capture the scalar read before entering the consumer,
   even if unused; preserve Number conversion, modulo and backing-storage read.
3. Preserve slot hygiene: ordinary inputs occupy slots zero through arity minus
   two; the removed tuple occupied arity minus one; its fields occupy arity and
   arity plus one. Generated helpers retain the original helper and use an
   injective new name. Nested unpacking uses fresh blocks. Initial-zero rebinding
   is not this rewrite.
4. Check actual output on full-array state and logical read/write events, a
   structurally different fold, consumer-write/earlier-write/unused-read cases,
   generated names and public hostile entry controls. Saved-output controls alone
   do not validate the production emitter. Record added bridge/body bytes even
   when an eligible helper receives no matching producer.

## Nonterminal-record vector proof

The production candidate should classify normalized type heads, after the
existing successful local-type proof. A canonical Sigma keeps its existing
vector representation. An ordinary record may use a private field vector only
when its eligible ordinary constructor is known and j_region_record rejects the
normalized type. Arrays and scalars are not ordinary record vectors. Do not use
not-j_region_record alone as an unchecked admission predicate.

The proof is by the existing closed graph boundary. Public region inputs are
scalars. Public outputs are scalars or the existing flat terminal record, whose
fields are all scalar. Private records cannot pass to unknown/foreign functions,
callbacks, casts or equality operations. The only container natives admit
Array<U32>, so an ordinary record cannot be stored in an escaping array. No
public result or its fields can therefore contain the newly vectorized type.
Every constructor and unpack point in that private graph must agree on its
representation, while public/generic definitions keep their boxed ABI.

PairBox{U32,U32} remains boxed, including as a field inside another private record.
Nest{PairBox,U32} and Dp{Array<U32>,...} may become vectors. This is narrower than
the saved-output experiment that unboxed PairBox inside selected scalar roots;
the type-based production rule needs no per-root representation context or
return reboxing. A type alias to PairBox is the critical refusal test: normalize
with wnf before j_region_record, or the alias can be misclassified as private.

## Minimal independent controls

Use the existing nested-record fixture and add a public Nat countdown returning
a flat PairBox, with initial zero and positive counts, plus a definition alias
to each record type. Inspect public results as boxed {$,a} values, not only their
numeric score. The scalar bench must exercise a vector Nest containing the same
boxed PairBox. A synthetic checked-predicate control should include canonical
Sigma, alias-Sigma, PairBox, alias-PairBox, Nest, alias-Nest, local-array record,
ordinary constructor named Tuple, primitive and Array refusals, recursive and
function-field refusal, erased fields and native/foreign metadata refusal.

Retain Phase31 prototype-marker controls. Removing an outer record allocation
must not weaken localGuard or expose private vectors to public forcing. Reuse
all full-state/native-event controls without changing their expected answer.
Reject a mismatch before timing. Separately report correctness, measurement and
promotion; static approval is only permission to run the next focused gate.
