# Phase16: one authoritative order for checking and instantiation

Prospective investigation, frozen before any chronology implementation. The
bounded local-order source04 is already measured separately. This design does
not authorize error-text arbitration or a second checker.

## The counterexample is inside one definition

`checker-all-04` actually ran these three controls:

```bend
import Base
def app(~f: Nat -> Nat, x: Nat) -> Nat:
  f(x)
def main() -> Nat:
  y = app(~(n => Nat.add(n, n)), 1n)
  True{}
```

Pinned TypeScript reports repeated consumption of `x` in `app~0`. Source04
reports the later `Bool`/`Nat` mismatch in `main`. A valid earlier instance
leaves the later mismatch first; an earlier ordinary type mismatch precedes an
invalid instance. All three reject in the checker, but the first diagnostic is
part of the strict contract. Evidence is bound by
`selfhost/build/phase16/checker-audit-03/report.json`.

Definition-event interleaving cannot fix the first witness. Merely moving
`sp_template` into `infer_template` is also insufficient: `sp_mint_type` first
walks the entire new instance through `sp_term`, then `sp_validate` calls
`check_definition_result`. That prewalk can select a later nested instance before
an earlier ordinary error inside the new instance. A fresh local state per call
also loses shared memoization, per-template numbering and active-cycle identity.

## Pinned semantics and existing ownership

At pinned commit `b2111cf43244e65f76ddc278ee695e669f720cbf`, `bend2/bend.ts`
`term_infer` at line 3248 and `def_inst` at line 3711 perform a live instantiation
at the reference encountered by the normal checker. Closed arguments are checked
in the empty caller context. A new instance is declared, checked immediately by
`def_check`, then installed. The next subterm sees its memo and book. Generic
source definitions use opaque parameters and do not instantiate nested templates
while checking generic text. Dead references do not instantiate. Existing
instances reuse the same name; active cross-instance calls are rejected. Names
are numbered separately for each template; depth and key length retain the
existing 64 and 32,768 limits.

`term_infer` also returns the number of consumed comptime applications. Its
application rule skips those nodes while returning an elaborated term. Our
`KChecked` currently returns term/type/uses/error, and many successful helpers
return the original term. State threading alone does not produce the final
backend tree: `infer_app_type`, lambda/constructor/match/let/rewrite reconstruction
and telescope argument accumulation must preserve checked children and erase
exactly the consumed applications.

The normal checker remains the only semantic authority. Normalization and
comparison remain pure readers of the currently visible book. Source declaration
and fill order remain owned by `dg_suffix_events`; errors continue through
KChecked/DTrace/DDiagnostic and the shared renderer. No diagnostic-text matching,
span ranking, speculative replay or semantic renaming is permitted.

## Alternatives and costs

| Approach | Correctness boundary | Complexity and expected cost |
| --- | --- | --- |
| Run the old specializer between definition events | Fails the measured same-body witness | Small change, insufficient; rejected as the next implementation |
| Invoke the old `sp_template` at each reference with fresh state | Loses shared memo/active identity and retains the instance prewalk ordering bug | Superficially small, incorrect; rejected |
| Thread existing state through the authoritative checker, retain a final memo-only materializer temporarily | Can enforce term order without immediately replacing every AST rebuilding helper | Broad result/environment plumbing; extra result or state field on checker calls; retains the second visitor temporarily |
| Thread shared state and return the elaborated tree from the same checker | Matches the reference architecture and can remove duplicated specialization traversal | Broadest single change, but simplest final ownership; needs explicit consumed-argument handling and every compound-term reconstruction |
| Reuse only DResult/source-event returns | Carries state between definitions but cannot carry it between recursive subterms | Useful final API boundary, not an alternative to term-level state |

The recommended destination is the fourth row. A representation-only ablation
should precede semantics, because this compiler spends most of its time in
checking. The third row is a possible temporary correctness checkpoint only if
it materially reduces implementation risk; it must not become a second checker.
Its final materializer would be allowed to resolve only already checked memo
entries and must refuse an unexpected missing instance rather than silently
minting or validating one. That restriction must itself be proven by controls.

No speed gain or net line reduction is claimed. The source04 specializer has
943 physical lines, 88 definitions and 55 laws. A read-only census identifies
31 traversal definitions and 30 laws occupying 296 block lines that might be
retired; this excludes unsafe marker lines and is not an achieved reduction.
The replacement checker plumbing and elaboration code must be counted against
that amount. `sp_type` currently re-infers terms whose types the normal checker
already knows, so removing that duplicate work is a plausible gain. Additional
state propagation and term reconstruction are plausible costs.

## Concrete state and signature choices

A wrapper `KCheckStep{checked: KChecked, state: KSpecState}` preserves the current
KChecked payload and avoids a recursive data dependency, but allocates a wrapper
at every recursive checking result and adds projection boilerplate. It is the
clearest isolated ablation, not an automatic final choice.

Putting a state field directly into KChecked avoids a second wrapper. However,
current KSpecState already contains KChecked as its error field; doing both
naively creates a recursive state/error representation with two error owners.
Instead separate the world (book, memo and fresh-ID bound) from the result's
error. The world has no error field; KChecked owns first failure. The global
instance serial can disappear because naming is per template. Preserve the
existing memo's active flag rather than adding an independent active stack.
`KEnv` holds the current world together with its existing name/lhs/pending/
quantities/unsafe data and instance depth. KChecked returns the resulting world
and, for inference, pending consumed comptime applications. Pure diagnostic
construction must not allocate or clone a populated world on an error path.

The following signature and sequencing families must be reviewed explicitly:

- `infer`, `infer_node`, `infer_ref`, `infer_template`: accept the current world,
  return the updated world and consumed-application count. The live/generic
  guards stay here. One shared instance worker validates closed arguments,
  looks up the memo, declares a fresh instance, calls the same
  `check_definition_result`, then publishes the completed instance.
- `infer_app`/`infer_app_type`: use the function result's world for the argument;
  decrement consumed comptime applications without checking them twice; combine
  the already elaborated function/argument only for remaining applications.
- `check`, `check_node`, `check_fits`, `checked` and `both`: preserve state on
  success and the first failure. Existing eager calls such as `both(check(a),
  check(b), ...)` must become explicit sequencing, because `b` requires `a`'s
  resulting world. Error precedence alone is insufficient if `b` used stale
  declarations or memo state.
- `tele_check` and its cached/static/legacy workers: sequence each argument from
  the previous result while retaining the substitution-stability optimization.
  Accumulate checked arguments if this stage produces the final elaborated tree.
- Lambda, let, constructor, match and rewrite workers: propagate state in pinned
  child order; retain quantity accounting, parallel-let caller contexts, branch
  use joins and the corrected motive-before-endpoint order. Rebuild terms from
  successful children while preserving original numeric source intervals.
- `check_definition_result`, `check_template_definition` and binder opening:
  preserve declaration visibility and opaque generic environments. Generic-local
  constants must not leak into the outer world's installed book.
- `dg_suffix_guard`/`dg_suffix_check`/`dg_suffix_finish`: carry the resulting world
  to the next source event, publish only completed bodies, and return the
  already materialized book through DResult after success.

A conservative textual call-graph census finds 48 kernel definitions that can
reach `infer_template`; this is a scope indicator, not an exact edit count.
KChecked constructor/pattern occurrences are currently confined to kernel
(seven), diagnostic/trace (five) and specialize (one). KEnv occurrences are in
kernel (14), specialize (four) and annotate (one). Therefore the smallest
principled design is a kernel result/environment change, not a two-function
specializer patch. The normal annotation pass needs a compatible pure entry
point after all template references have been materialized.

## Cache, host and TODO boundaries

The chronological checker uses a persistent cached book; the specializer uses
plain lists plus `Con`/`index_remove`. Never insert a cached book into those
plain-list mutation helpers. Either keep the representations separate during an
ablation or convert all instance installation operations to the existing
cache-aware book API and verify exact visibility and invalidation. The final
world should have one authoritative book, not two independently drifting copies.

A cached prefix must bind the exact compiler ABI, source prefix, and any already
checked instance state. The read-only bound-Base census found 488 declarations,
25 templates, and zero non-template bodies referencing templates. This supports
only that exact identity, not skipping arbitrary validated prefixes containing
live instances. General prefixes must preserve/replay their instance state or
fall back to a full authoritative check.

If `compiler_check_result_abi` advances to 2, define it to mean DResult contains
the completed checked/materialized book. The host may skip the old second
specialization pass only for that capability. Preserve historical ABI0/1
behavior and error rendering in explicit mock controls. Timing must compare the
whole host check-plus-trust path: existing samples already include specialization,
so an internal `check_book` timing alone would compare different work boundaries.

TODOs are not ordinary early type errors upstream: parsing records them and
unfilled final laws add to the count. A checked TODO may pass its expected type;
the final compiler refusal occurs after other authoritative checking, including
live instances. Use one existing source-hole/open-law accounting path rather
than counting elaborated copies or substituting a diagnostic message early.
Keep TODO inference distinct from expected-type checking and test both.

## Staged acceptance gates before promotion

1. Freeze the representation-only candidate and compare exact whole-host output
   with source04 plus the integrated source ranges. Measure time and RSS before
   adding semantic effects. Avoid general heap overhead justified by an
   unmeasured future speed gain.
2. Make one shared worker mint/check instances at `infer_template`, preserving
   the normal checker. Run all three same-body witnesses plus the same order
   reversed inside a newly minted instance. Cover two templates with interleaved
   names, repeated memo hits, direct decreasing recursion, cross-instance cycles,
   growth, dead calls and generic source text.
3. Require prior 84 rows and focused controls for earlier/later source failures,
   TODO versus live templates, imports/fills, cached prefixes, unsafe reporting,
   and a valid imported call. Track every primitive change separately; only
   intentionally measured semantic fixes may differ from the previous compiler.
4. Integrate one elaborated return path and retire the duplicate traversal once
   generated-code/output and backend checks pass. Run the full 2,996 observation
   vector without losing prior exact rows, then controlled whole-host timing
   against both the installed baseline and pinned TypeScript.

Owned implementation files, if this design proceeds: `src/check/kernel.bend`,
`src/check/specialize.bend`, result transport in `src/diagnostic/trace.bend`, event
transport in `src/diagnostic/produce.bend`, compatibility calls in
`src/check/annotate.bend`, and `tools/typed-driver.mjs`. Coordinate these hunks
against the source-range owner's shared snapshot. No production chronology edit
has been made for this investigation.
