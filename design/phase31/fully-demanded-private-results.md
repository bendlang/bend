# Fully demanded results inside a closed private region

Prospective semantic review after actual04's correctness gates, before any
strict-result derivative is run or timed. This proposal changes only private
workers. Public descriptors, raw callback entry, saved public bounces, generic
fallback, and the existing public terminal-record behavior remain unchanged.

## Claim and useful boundary

For the currently admitted first-order graph, every private helper can return a
fully demanded ordinary value. Its caller can then omit the redundant `force`
around a non-tail private application. The existing record and array layouts
remain; no ownership uniqueness, storage change, or algorithmic shortcut follows.

The graph has scalar public inputs. Its arrays originate in validated local
Array<U32> allocation, and its only array operations are the validated new/get/set
natives. Records have a finite accepted field structure; functions, foreign calls,
unknown operations, global container references, and partial private applications
are rejected. Private calls are closed over original-definition snapshots. The
entry guard rejects primitive/Object/Array marker hooks before private work.
Stable host intrinsics remain part of the existing scope. Thus private fields
contain neither arbitrary callbacks nor host-provided proxies/getters, and no
private delayed result can be stored in an escaping callback or global location.

Keep scalar roots scalar out. Existing public Nat workers may also return their
already admitted inert flat scalar records; preserve that public return machinery
and its field-value restriction. This exception does not permit returning a
delayed local array computation across the guarded boundary.

## Why this differs from making an arbitrary field eager

Constructing a delayed write, reading an alias, and then demanding the write must
remain distinct operations. The retained earlier witness observes 0 before the
delayed demand but 9 under that incorrect eager rewrite.

Here the proposed transformation acts only at private call results in contexts
that already demand them. Every such occurrence is one of:

1. A non-tail argument or Let RHS. The original emitter fully forces the result
   before evaluating the following sibling expression or entering the callee.
2. The tail result of a private helper or constructor-field thunk already being
   demanded. No source computation runs between returning that delayed result
   and the caller's next force step. Returning the completely demanded result
   performs the same local operations before the same next sibling.

It does not take a delayed write past an intervening source read. It removes the
representation of the demand when the caller is already committed to doing it.

## Operational argument for the admitted grammar

Let D mean the existing complete `force` operation. Establish the invariant
that each private worker argument and ordinary local binder contains a fully
demanded admitted value. Compare original D(expression) with the strict worker
expression, preserving both result/handle identities and ordered native effects.

- Literals and variables are already demanded by the invariant.
- Scalar operations and the three validated native operations receive arguments
  in the original order and return ordinary scalar, handle, or Tuple values.
  Under the guard, forcing those values has no additional callback or write.
- A non-tail constructor already evaluates its fields in source order. A tail
  constructor returns a build whose enclosing D evaluates and demands each field
  in that same order. An eager private constructor performs those demands at
  that encounter point, before the same next sibling. Nested constructors use
  the same argument recursively; they retain the same array handles.
- A private call evaluates its arguments before entering the helper, in the
  existing left-to-right order. A non-tail call's outer D becomes redundant when
  the helper satisfies the strict-result contract. For a tail call, its bounce
  was the next action of the current D; direct execution performs that action
  without allowing another source expression to intervene.
- Constructor elimination receives an already demanded value. Keep the current
  complete specialized field telescope and projection/copy behavior. A strict
  return rule does not alter match arity, prefix slots, or alias identity.
- Let retains its original parallel-RHS environment and evaluation order. Each
  result is demanded before the next RHS; fresh immutable binder identities
  remain unchanged.
- Nat countdowns evaluate all next arguments in order before transferring. Their
  zero arms obey the same strict-result contract. In particular, row's zero swap
  remains, while dp's zero identity remains. Existing fresh iteration aliases
  prevent delayed references to a mutable loop slot.

This is a bounded operational proof sketch for the admitted grammar, not a
general strictness theorem for Bend. It relies on the existing locality and
closed-call proof. It does not justify changing public scheduling, arbitrary
effects, function fields, recursive lazy records, or host-visible values.

## Smallest implementation and required checks

The likely code experiment is to emit `j_region_return` with tail=False and make
the private JCall demand wrapper an identity. Audit all `j_region_return` callers:
they must be private helper returns or transformed private zero arms. Keep the
public generic body and its `j_constructor_mode(..., tail=True)` unchanged.
Do not remove `force` from the runtime or arbitrary emitted calls.

Before timing, inspect the actual generated private bodies: every successful
return path must produce a demanded admitted value, with no surviving private
build/jump result. A missed return path invalidates removing its caller's force.
The acyclic helper-depth bound and existing Nat loops remain; the change must
not introduce unbounded JavaScript recursion.

Renew complete arrays and all 328,966 native events on a real edit-distance pair,
plus the single-array fold's wraparound and delayed-first-field cases. Renew the
nested-record fixture, zero and nonzero entries, saved aliases, and full public
fallback controls. The Array-free Sigma mutation witness must still reject the
bad guard and match the old compiler under the real guard. Public callbacks must
retain their raw/constructed/saved result observations. Compare operation counts
separately; fewer builds or forces are not themselves performance evidence.

Only a frozen alternating comparison of the actual strict-result module with
actual04 and the earlier generic baseline can establish the incremental speed
gain. Retain a failed or neutral result without widening admission to rescue it.
