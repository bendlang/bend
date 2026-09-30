# Direct field reads from proved local products

Prospective follow-up to fully demanded private results. This document establishes
the proposed semantic boundary; it does not report an executed implementation or
speed result. Public matching, generic fallback, and foreign-object projection
remain unchanged.

## Two layouts, selected by proof

The admitted ordinary record has a single user constructor. Its checked header
has `db(c) == false`; `j_ctor_keys` emits `constructorNative[name] = false`, and
the runtime `ctor` therefore returns `{ $: name, a: fields }`. The private value
has an own plain `a` field referring to a dense array of exactly the specialized
constructor's live fields.

The admitted canonical Sigma has native-owner and Tuple-constructor provenance.
After specializing its four parameters, its constructor has exactly two live
fields. Runtime Tuple construction and the admitted Array.get native both produce
a dense two-element JavaScript Array. Nested Sigma products keep their nested
two-slot layouts; they are not flattened into a larger vector.

Select these layouts from the checked input type in the private plan. The text
`Tuple` alone is not a proof. For example, retain the matched argument type as a
second JUnpack child, or record a discriminator created only after the canonical
Sigma check. The emitter may then use `arg[i]` for that Sigma and `arg.a[i]` for
an ordinary admitted constructor. Constructor names remain useful for diagnostics
but do not decide representation on their own.

## Why projection and copying can disappear here

The source analysis admits no foreign container, arbitrary callback, function
field, global container reference, or public container argument into the private
region. All product values originate from the above constructors or native get.
Their full specialized field telescope is checked; eta-short or unknown match
arms are rejected. The existing entry guard refuses marker callbacks before
private work and retains the declared stable host-intrinsics scope.

The field vector itself cannot be mutated by an admitted operation. Array.set
accepts an Array<U32> handle and changes its backing store; neither a record's
field vector nor a Sigma tuple is such a handle. Individual fields can contain
aliased mutable handles, and those aliases must remain exactly the same objects.
Removing a copy of the immutable outer vector neither copies nor deduplicates
the underlying arrays.

Keep the current IIFE initially. It snapshots field values through positional
arguments, evaluated left to right before entering the body. Earlier scalar
parameters retain their slots; new field binders start after all ordinary helper
parameters. Thus a later body write cannot change which field values were passed.
Repeated reads of the plain own `a` property are inert in this admitted domain.

For zero-field ordinary records, the projection/copy has no required private
effect and the zero-argument IIFE suffices. Public malformed objects, getters,
proxies, missing fields, custom iterators and fabricated constructor payloads
still use the existing public matcher and its generic projection behavior.

## Validation before measurement

Require actual compiled output to use the direct reads only in proved private
helpers. Renew nested record and nested Sigma fixtures, ordinary prefix-slot
tests, zero-field/zero-loop cases, and the complete original pair's array/event
oracle. Keep array-handle alias tests and public field getter/proxy traces.
The Array-free Sigma mutation witness must still fall back under the real guard;
removing projection is not permission to weaken that guard.

Use the existing independent event instrumentation to establish unchanged native
allocation/read/write order. Count private project and slice sites separately.
Freeze a same-window comparison against the preceding actual compiler output
before interpreting a reduction in administration as an execution speed gain.
