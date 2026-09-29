# Phase19: one owner for live instance checking and output

Prospective design for review. No Phase19 compiler edits or probes have run.
The parent is the frozen Phase18 `instance-world-source-06/project`, checked as
`instance-world-build-06`, API
`9f9648cbfc53912cd38fa78758b3409fea431f93dd285a0e911cbd373e5579ae`.
The [Stage1 report](../../implementation/phase18/instance-world-public-boundary.md)
closes public18, transport42, whole-outcome22 and memo8. It adds 107 production
lines and three types; its source03 cost screen was neutral. Source06 itself has
no controlled timing result. Phase18 inputs stay immutable.

This phase is independent of the proposed parser cursor slice. Work uses new
`selfhost/build/phase19/instance-*`, `selfhost/tools/performance/phase19/instance-*`
and `implementation/phase19/instance-*` paths. Pinned upstream remains
`b2111cf43244e65f76ddc278ee695e669f720cbf`; no TypeScript edits or fallback.

## Evidence and intended change

Two frozen observations differ from the pin:

1. `p17-instance/instance-before-type`: an invalid first live instance must fail
   before a later ordinary type mismatch in the caller.
2. `p17-nested/local-before-instance`: a local lambda inside a new instance must
   fail when its binder closes, before a later invalid nested instance.

The reverse-order and valid-side controls already agree. The earlier direct
`f(x)` proposal was falsified because its outer binder closes after the nested
call; retain that control and the recorded finding. Do not assign an error rank
or merely move the existing prewalk between definition events.

The pinned `term_infer` Ref/App rules and `def_inst` perform immediate checking
at the first live template reference. `def_inst` reserves a name and bodiless
placeholder before recursively calling the same `def_check`; a successful
instance has separate original `v` and checked `e`. `book_valid` retains every
declaration but publishes a source body only at its completed final event.
Instances do not enter source event order. These are the ownership boundaries
to reproduce, not diagnostic-text heuristics.

## Choose the complete path before a temporary pass

| Approach | Work it retains | Additional correctness boundary |
| --- | --- | --- |
| Immediate checking plus old specializer adapted to memo lookup | A second contextual term traversal, quantity/type reconstruction and source-event replay | It must recreate the source visibility at every first call; final-book queries can unfold later law bodies. Current `sp_type` also calls `infer` at dead demand and `sp_template_checked` repeats closed-argument checking. |
| Immediate checking plus checked-child return and an output accumulator | The existing backend annotation pass; no specialization term visitor | Every rule must return its checked children while all goals, keys and semantic unfolding retain original source terms. |

Recommend the second path now. A memo-only temporary visitor is smaller only if
one ignores its context/history ownership. Replacing `sp_type` with the existing
annotation type projection would remove one recheck, but would not remove that
second owner of event visibility. Building that intermediate architecture and
then deleting it is unlikely to be the shortest route to one usable compiler.

Here, the final **memo-only materializer is only a book assembler**. It selects
already completed checked definitions and completed instance entries. It does
not walk terms, infer types, compare goals, mint, validate, or select a language
diagnostic. A missing output for a completed memo is an internal invariant failure,
never permission to fall back to the former visitor. Keep backend annotation
unchanged initially; removing it would be another semantic and backend project.

## Internal interfaces and public boundaries

Keep KEnv7 and KChecking6 from Phase18. Add one field to the world, allocated
only when state changes:

```
KWorld { book: List<KDef>, memo: List<KSpecMemo>, fresh: KWorldFresh,
         checked: List<KDef> }
KChecking { term, typ, uses, error, world, consumed }
DChecking { result: KChecking, diagnostic: DDiagnostic }
```

`book` is the sole semantic source book. `checked` is a persistent accumulator of
completed output definitions; it is never read by `wnf`, `compare`, source key
encoding, or declaration checks. It holds output data, not a second checker.
The extra DChecking wrapper exists only at the source-event/result boundary so
the existing contextual diagnostic and real world survive together until public
projection. It is not allocated per term and creates no error/world recursion.

On success, `KChecking.term` is the checked, specialized core output for the input
term. It uses the current KTerm/KLambda/KLiteral representation, not a new AST or
the backend's annotation format. `typ` remains the semantic source type. On
failure, `term` retains the existing diagnostic payload and `world` the actual
failed semantic state. `consumed` is used only while unwinding the pending App
spine whose template head consumed closed arguments; it is not an effect count.

Add a small environment-with-world projection. Keep the other owner/lhs/pending/
quantity/unsafe/depth fields unchanged when continuing a child. The same `infer`
and `check` functions check source definitions and minted instances. Split the
existing definition entry into signature checking and body checking so a minted
instance, whose residual telescope was already validated by closed-argument
checking, follows pinned `def_check` without another signature pass.

Public shapes stay explicit:

| Entry | Result/contract |
| --- | --- |
| `check_book`, `check_from_exact_prefix` | String projection from the shared event checker; preserve their open-law completion contract. |
| `check_book_diagnostic`, `check_book_diagnostic_from_exact_prefix` | Historical DResult. Successful book remains the original source book; rejected results carry the real failing semantic book for diagnostic normalization. |
| `check_program_diagnostic` | Checker ABI2 DResult containing completed output on success, with final TODO counting after real checking. The host must not specialize it again. |
| `specialize_book` | Historical KSpecialized/KChecked4 projection through the same authority and output assembler; no independent validating visitor. Valid source and repeated materialized-book controls are required. |
| `specialized_book/error/diagnostic` | The frozen public projection and demand contracts from Phase18. No reconstruction of an invented world. |

Source-order checks, prefix replay and completion use one internal event worker
returning DChecking. Existing public completion choices remain adapters; there
is no second event checker. General `specialize_book` inputs cannot be treated
as possessing hidden memo state. If a standalone call needs validation, it uses
that same worker. Invalid raw inputs may therefore reject earlier according to
the pin; declare and control that behavior, rather than claiming all historical
invalid-input values are unchanged. The normal ABI2 path does not run it twice.

Term ABI1, source-span ABI3, load ABI and cache6 do not change just because these
private records change. No new capability number is needed if public shapes and
completion promises remain the same. Any discovered public shape or cached-world
extension requires an explicit version change and separate host review first.

## The live reference operation

1. Look up the source declaration. Preserve undefined-name, family and erased
   reference behavior. Determine whether this live reference is a template call
   outside a template's generic source body.
2. Apply the pinned unfilled-law rule **before** instantiating. Unsafe permission
   does not permit an unfilled template body. After instantiation, self descent
   compares the instantiated name with the current owner and uses the residual
   runtime spine. This differs from the present pre-instantiation self check.
3. Check the required closed arguments at dead demand in the empty context,
   left to right, using the same telescope/checker. Preserve the source arguments
   for substitution and keys. The returned residual source telescope is reused;
   do not validate the arguments again in an output pass.
4. Reuse the exact canonical JSON key encoder and UTF16 `sp_len` guard. Reject
   a key longer than 32768 units before memo lookup/reservation. Do not normalize
   syntax identity, discard lambda quantity presence, include spans, or introduce
   a shorter private key with a different growth boundary.
5. Reuse `sp_find`, per-template `sp_ordinal` and active/completed semantics.
   A completed hit reuses its name. An active hit from another owner rejects as
   a cross-instance cycle; an active hit of the current owner proceeds to the
   ordinary residual-spine descent check. Unsafe self descent and cross-instance
   cycle rules remain distinct.
6. On a miss, reject a new depth beyond 64, reserve its canonical name and active
   memo, and install a bodiless source placeholder using `book_put`. Freshen the
   source type/body with the existing structural `sp_shift`, then instantiate
   from original closed arguments. Preserve source ranges and literal/lambda
   syntax metadata. No `sp_term` prewalk occurs.
7. Immediately check that instantiated source body through the same body checker,
   with its new owner and incremented depth. On failure return it unchanged;
   the active placeholder and real scoped book remain available to diagnostics.
8. On success publish the original instantiated body in the semantic source book,
   its returned checked body in the output accumulator, and complete its memo.
   Preserve all nested memo/fresh/output changes from the returned world. Do not
   reconstruct from the pre-call state as current `sp_validate_done` does.
9. Return the instance Ref, residual source type, empty closed-argument usage,
   updated world and the exact number of consumed applications. Keep the original
   reference's origin. Each surrounding App first decrements a positive consumed
   count and returns; it does not normalize a function type or check that argument
   again. Real nested App controls must prove this, not just injected counters.

## Sequential checking and checked output

Every continuation uses the returned world before looking up, normalizing,
comparing or checking its next child. `both(check(a),check(b),...)` is eager and
cannot implement short circuiting. Keep `both` as a usage/result combiner only
after the second premise has been conditionally evaluated. Avoid a generic
monadic interpreter or a second recursive checker; use the existing rule workers
and small named continuations.

| Rule family | Required order and source/output distinction |
| --- | --- |
| Min, All, Eql, Ann | Follow pinned premise order; rebuild with checked children. Ann's semantic type remains the raw annotation, and its output preserves the annotation needed by current backend consumers. |
| App | Function first; consume comptime spine if present; otherwise normalize in its returned source world, check the argument there and substitute the **raw** argument into the source codomain. Output combines checked function and argument. |
| Lambda | Optional Many kind check, body, then usage closure. Preserve lhs stepping and return a rebuilt output lambda. Source lambda quantity presence stays untouched for keys; backend annotation retains its existing clearing policy. |
| Telescope/ADT/Ctr | Check each argument before the next; source substitution uses raw arguments. Carry checked arguments in the existing internal Args payload. Preserve cached/static substitution fast paths while making every tail conditional on success. |
| Parallel let | Each value uses the outer lexical context but the current returned world; then its kind check. Only the body sees all binders. Keep raw values in semantic lazy cells; output contains checked bindings/body and strips semantic value-cell payloads from output variables. Close binder usage in pinned order. |
| Match | Check selected arm, then the remaining cases using the returned world; usage joins remain branch joins. Preserve the existing unreachable-fallback rule and do not visit its discarded default. |
| Rewrite | Evidence, evidence type normalization, dead motive, motive-fit comparison, body. Every step uses the preceding returned source world and raw source expressions for goals. |
| Definition/constructors | Signature before body; constructors and domains in their existing order. Publish only a successful final source event; instances remain outside event order. |

`check_fits`, `infer_app`, `check_rwt`, `check_definition_type`, telescope fast
paths and constructor continuations currently read their enclosing environment
after a child. Audit these explicitly; preserving only the result record is not
enough. Diagnostic reason construction must also use the failed world's semantic
book where it consults declarations. Outer trace/name/source-range context stays
with the actual failing term; preserve note predicates and first-error transport.

Output rebuilding must not silently change unrelated public or backend behavior.
In particular, preserve annotations, local binder IDs, removal sets, source ranges,
literal identity and absence/presence of lambda quantities. Direct raw API inputs
with beta-redexes or semantic Var cells need explicit output controls: the old
specializer skipped some unchanged bodies, whereas the checker observes their
canonical form. Declare any intentional canonical output difference separately
from acceptance/diagnostic conformance; do not call it byte equality.

## Generic scope, freshness and indexed books

Generic source checking opens each `~` binder as an opaque local definition.
Successful generic output must retain the original generic source definition,
not a body mentioning temporary `owner~binder` constants. Failure retains the
actual private scope for diagnostics.

Pinned `def_check` creates a prototype-backed local `tlds` view but shares `tmps`;
ordinary live instantiation is suppressed while the owner still has template
parameters. First prove and control that suppression invariant, including nested
applications, captured laws and normalization. Do not assume it from a string
prefix. If no mint can occur within that scope, restoring just its saved source
view is justified by the invariant, while preserving carried memo/fresh/output.
If a reachable operation can mint there, stop and design a proper overlay/merge
with the pin; blindly restoring the whole old world or exporting private names
is unacceptable. This is a first cheap falsification gate, before broad migration.

Use `book_put` for placeholder/body publication into a BookCache. Current
specializer `Con` plus `index_remove` is for its plain list and must not be copied
onto the indexed checker book. Keep cached bound metadata consistent with minted
IDs. Do not traverse trie implementation nodes as ordinary language definitions.

At program entry, reuse the maximum already computed by `dg_seed_books` on the
full original source book to construct Known; do not add a second full scan.
An arbitrary private/plain-book entry remains Deferred until an actual mint.
Resolving Deferred must cover visible source definitions, the current owner's
full source type/body (which may not yet be published), context, lhs, pending
arguments, goals and generated temporaries. Known describes that complete domain,
not just the current visible book.

Audit the two checker-generated ID sites specifically: `mat_lhs/lhs_ext` and
`check_rwt_goal`. They must reserve their live temporary range in the world before
a nested mint can occur. Advance the bound on minted source bodies and retain it
on every failure. No inference from zero, source positions, or a guessed count;
no new traversal of poisoned/unneeded bodies when no mint is demanded. Overflow
must fail closed rather than wrap into existing binder IDs. Record any earlier
out-of-scope raw API limitation instead of silently broadening this claim.

## Prefixes, completion and failure projection

Cache6 stores validated source definitions, not a KWorld or instance memo.
An arbitrary exact source prefix therefore cannot be skipped while starting an
empty memo. Initial Phase19 correctness replays such prefixes through the same
checker and reconstructs their world; exact-prefix comparison still guards the
input identity. This may cost time and must be measured. No unproved Base-only
exception, stale cached book, or hidden host-side memo is permitted.

A later skip would require an explicit compiler/Base-bound certificate proving
the needed instance state, or a versioned validated-world cache with full public
compatibility controls. Base contains templates, so absence of template syntax
is not a valid argument. This followup is outside the first Stage19 slice.

On failure, DResult.book must be the actual failing semantic source world before
stable projection, including the active instance or generic private scope needed
to normalize expected/observed terms. The current `dg_suffix_check(done,...)` and
`sp_finish(sp_book(st))` choices are insufficient once children produce effects.
Preserve numeric origins independently of generated instance names. Public
KSpecialized projects KChecked4 only after the real semantic book has been chosen;
its renderer shares the existing payload renderer and invents no world.

Program completion counts original-source TODOs only after source and demanded
instance checking, in the existing ABI2 order. Trust/unsafe reporting still uses
the source claims. Output assembly includes completed source definitions and
instances exactly once, with deterministic names/order and no private constants
or cache sentinels. It never changes the success/failure decision.

## Scope, deletion ledger and cost

Expected files: `check/kernel.bend`, `check/specialize.bend`, `diagnostic/trace.bend`,
`diagnostic/produce.bend`, `driver/api.bend`; small adaptations in `check/annotate.bend`
and `check/prefix.bend` if needed. A bound-update helper may belong in core/index;
declare that hunk separately. No parser/core-term representation change is part
of this phase, and no production instrumentation exports enter the candidate.

Static census on source06 gives the following explicit retirement targets:

- The former contextual specialization visitor is **29 definitions, 28 laws,
  280 declaration-block lines** excluding unsafe markers: `sp_term`, annotation/
  lambda/constructor helpers, argument/spine helpers, match/let/rewrite helpers
  and `sp_type`. Direct checked output should remove this family, not retain it
  under another name.
- Closed-argument recheck helpers `sp_template_args` and `sp_template_checked`
  account for **two definitions/two laws/25 block lines**. Their validation moves
  to the existing checker telescope once; remove the duplicate pass.
- `sp_mint_type`, `sp_mint_body`, `sp_validate`, `sp_validate_done` account for
  **four definitions/four laws/35 block lines**. Replace their prewalk/validate
  chain with the direct checker call and completion worker. This is replacement
  work, not all net deletion.
- Retire private KSpecState/KSpecTerm/KSpecTerms once their callers disappear;
  preserve KSpecMemo, KSpecialized and public KChecked4. The proposed DChecking
  wrapper adds one private type, so the record target is net two fewer types than
  source06, plus one output field in KWorld. Count the real final result.
- Keep canonical key encoding, exact size/depth limits, source shifting, memo
  lookup/naming and active-cycle concepts. They are language requirements.

The Phase17 kernel-only reachable census found at least 47 functions upstream of
template inference; this is a broad sequencing change. New continuations and
output reconstruction can offset the deleted visitor. The planning target is no
more than roughly 200 net added production lines over source06 while removing
the second semantic traversal owner; this is a review trigger, not permission to
compress formatting or claim a guaranteed reduction. Report physical/nonblank
lines, bytes, definitions, laws, types and remaining owners separately. Compiler-
wide 50%/75% simplification remains unachieved.

No speed multiplier is forecast. The concrete work removed is the specialization
term prewalk, its erased re-inference and repeat closed-argument/instance checking.
The new costs are checked-child allocations, an output accumulator, world-bearing
continuations and initially prefix replay. Separate operation counts from final
whole-host measurements; no inference from a faster tiny witness.

## Sequential implementation and first cheap gates

1. **Freeze the interfaces and ownership above for root review.** Source-only
   census/control preparation may proceed. No compiler mutation until approval.
2. **Cheap invariant proof:** add finite paired source witnesses for generic
   suppression, captured local laws, source-vs-output identity, later law fills,
   nested App consumption and generated fresh temporaries. Preserve all failures.
   A private named-probe entry may expose the shared checker during construction;
   label that scope and do not claim public completion from it. Add no second
   checker or permanent enable flag merely to keep an incomplete public route.
3. **One isolated coherent checker slice:** implement world sequencing, immediate
   mint/check and checked output together. Genuine checked B1 first, then the
   saved22 observations and memo8. Exactly the two saved diagnostics should become
   strict TS matches; the other20 and all eight name sets must remain exact.
   Validate the deepest failing owner/source range, not just the error string.
4. **Close public completion:** shared event result/projections, general-prefix
   replay, output assembly, deletion of the old visitor. Rerun frozen public18
   and transport42 with explicit internal-layout probe adaptations, plus default36.
   Cover repeated raw specialization and unchanged historical KChecked4 inputs.
5. **Boundary matrix:** real zero/one/multiple consumed applications; type and
   ordinary error on either side; generic/local law scopes; earlier/later source
   failures; imported calls; TODO/unsafe order; memo hit after an effect; active
   self/cross cycles; 64-depth and both saved growth refusal positions. Reuse
   canonical-key61, parsed-instance29, growth2, literal176 and demand controls
   where their mechanisms are touched. Do not replace strict expectations.
6. **Integration gate:** complete frontend2996, prior histories226, backend41 and
   literal execution20, host/cache controls and installed/relocated smoke before
   promotion. Record intended new controls separately from the main corpus's two
   unrelated parser gaps. Stable acceptance does not prove emitted behavior.
7. **Controlled cost:** root coordinates exclusive same-final-source TS/B/C/C/B/TS
   fresh processes with exact hosts, stack/heap and cache policy recorded. Compare
   whole check-plus-trust work, output/memo allocations and peak RSS. Prefix replay
   is part of candidate cost, not removed from the denominator. Reprofile only if
   measured cost requires it. Do not install an incomplete private slice.

Stop on wrong precedence, missing output, changed key boundary, leaked scope,
fresh-ID collision, lost first failure, or changed unrelated primitive outcomes.
If making output direct requires a second full checker/history, revisit this
design rather than quietly rebuilding the rejected temporary architecture.
