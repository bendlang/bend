# Phase19 frozen implementation interfaces

Root approved this direct-output slice on 2026-09-29 after reviewing
[the design](live-instance-checking.md). This addendum fixes the small record and
file-ownership details before shared source preparation. No semantic implementation
is asserted by this file. Phase18 source06 remains the exact immutable parent.

```
KWorldFresh = KFreshKnown { next: U32 }
            | KFreshDeferred { roots: List<KTerm> }
KWorld { book: List<KDef>, memo: List<KSpecMemo>, fresh: KWorldFresh,
         checked: List<KDef> }
KChecking { term, typ, uses, error, world, consumed }  # unchanged six fields
KEnv { world, name, lhs, pending, quantities, unsafe, depth }  # unchanged
DChecking { result: KChecking, diagnostic: DDiagnostic }
```

The kernel owner provides these helpers:

- `kw_initial(book) -> KWorld`: empty memo/output, Deferred Nil, no book demand.
- `kw_seed(book,bound) -> KWorld`: the event owner passes the maximum already
  computed over full original source. Known is bound+1 when representable;
  U32 maximum remains Deferred so no-mint paths do not acquire a new refusal.
- `kw_book`, `kw_memo`, `kw_fresh`, `kw_checked`: direct projections.
- `kw_with_book(world,book)`, `kw_with_checked(world,checked)`: replace only the
  named field and preserve the other three.
- `kw_put_checked(world,d)`: prepend one completed unique-name definition. Source
  events call it only at their final fill; minted instance names are unique.
- `ke_world(e,world) -> KEnv`: replace only the environment world.
- `check_definition_world(world,d,depth) -> KChecking`: check signature then body,
  returning an output body in term and nested instance effects in world. It does
  not publish d itself. Signature failures keep their actual result world.
- `check_definition_body(world,d,depth) -> KChecking`: the same body checker
  without rechecking a previously validated signature; instance mint uses this.

The event owner owns `diagnostic/produce.bend`, `check/prefix.bend` and, where
needed, `driver/api.bend`. It defines DChecking, threads worlds across source
events, chooses existing public completion policies and performs stable public
projection. On a completed final source event it publishes original d into the
source book and `d{value:ct(result)}` into the output accumulator. Generic output
retains original d, since generic checking uses opaque temporary constants.

The kernel owner owns `check/kernel.bend`, `check/specialize.bend` and the small
world-sensitive hunks in `diagnostic/trace.bend`. It provides KWorld helpers,
ordered child continuations, immediate mint/check and checked output rebuilding.
Mint publishes its original instantiated body and checked body only after its
own check succeeds, preserving nested returned effects. It also owns a tiny
cache-bound update helper; no global normalizer changes are planned.

The former `specialize_book` wrapper will need the event owner's common runner.
Coordinate that one call signature before source closure; no duplicate program
checker is introduced. Historical KSpecialized/KChecked4 and the three projection
functions remain. The output assembler only selects completed output data, never
walks/checks a term. The kernel owner removes KSpecState/KSpecTerm/KSpecTerms and
the former specialization visitor once all callers migrate.

Deferred roots retain already demanded original owner type/body terms without
walking them. Add them only after the body's existing demand point; do not read
the body while setting up a failing signature. A real mint resolves the source
book plus roots, ctx, lhs, pending spine, goals and temporary IDs. Known.next is
a strict upper bound over that entire active domain. Reserve match/rewrite
temporaries before children and update the BookCache bound when it grows.
Overflow refuses only when allocation is demanded; it must not wrap.

Independent pinned-source review confirms the generic-owner suppression guard:
there is one def_inst call, guarded by owner.x==0. Generic def_check retains
owner.x>0 in its private prototype view; WNF/compare cannot mint. Therefore a
successful generic scope restores only its saved source-book view while retaining
returned memo/fresh/checked; failure retains its private view. Finite controls
still cover nested calls, alias/captured-law normalization, a preceding completed
instance and an error needing owner~binder. No broader scope-merge concept is
introduced absent a counterexample.

The shared preparation is `selfhost/build/phase19/instance-source-01/project`,
initially an exact 214-file copy of Phase18 source06. Each owner writes only its
named files. The parent manifest binds the copy before edits; final owner patches
and a combined manifest bind it after both owners close. No compiler job starts
until root signals that event/public boundary files are ready. First gates remain
the saved22 chronology observations plus memo8, before broader integration.
