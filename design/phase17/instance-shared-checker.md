# Phase17: proposed correction after the live-instance witnesses

Proposal for root review; no compiler implementation is authorized by this file.
Evidence and source identities are in `implementation/phase17/instance-chronology.json`.

## What must change

The unchanged installed compiler has two distinct observed order failures. A live
invalid instance before an ordinary mismatch loses to that later mismatch. Inside
a newly minted instance, a completed local lambda can fail before a later nested
instance, but the existing specialization prewalk chooses the nested error first.
Moving specialization between definitions fixes neither boundary. Calling the
current `sp_template` at `infer_template` still contains the second prewalk.

Reuse the authoritative checker for both caller and instance. One immutable world
owns the currently visible source book, existing per-template memo/active state,
and fresh-ID bound. Instantiation at a live reference takes that world, validates
closed arguments, looks up or reserves the canonical key, declares a placeholder,
checks the new instance immediately with the same checker, publishes its source
body, and returns the updated world and instance reference. The caller resumes
only after that result succeeds. Do not add another checker or diagnostic ranking.

The reference's source and checked bodies are distinct (`Def.v` and `Def.e`). Our
KDef has one body. The authoritative semantic book must continue to hold source
bodies while checking later terms. Fully elaborated output belongs in a separate
output accumulator, or in a temporary memo-only materialization step after all
checking succeeds. Replacing every source body with checked output without a
proof can change subsequent normalization and raw syntax used for instance keys.
This output is not a second semantic book or a second validation authority.

## Smallest practical stages

1. **Representation cost checkpoint.** In a fresh isolated candidate, replace
   KEnv's book with a world reference and add instance depth. Extend the normal
   result with returned world and consumed-comptime-application count. Keep
   behavior unchanged and count every new field/helper/line. World records should
   be shared on ordinary paths and allocated only when book/memo/fresh state
   changes. Measure complete CLI check-plus-trust time and memory against the
   same installed source; this is an ablation, not a performance claim. Do not
   proceed if the extra result transport creates an unacceptable unexplained
   regression.
2. **One checking order.** Sequence compound child checks through returned world;
   put key lookup/reservation and immediate instance checking at infer_template.
   Replace `sp_mint_type -> sp_term -> sp_validate` with that same checker call.
   Keep original source bodies in the semantic book. A temporary postcheck
   materializer may only resolve already validated memo entries and rebuild the
   output. It must fail an unexpected memo miss, never mint or validate, and
   never choose a diagnostic. This temporary step retains duplicate traversal
   cost and must be named as such.
3. **One elaborated traversal.** Return checked children and accumulate checked
   output definitions, then remove that temporary materializer and its type
   re-inference helpers. Count replacement plumbing against deleted visitor
   code; no net source reduction is assumed. This stage is desirable only with
   full correctness and cost evidence.

Use a world without an error field. KChecked remains the single first-failure
owner; blindly embedding today's KSpecState in KChecked would make a recursive
state/error structure. Error metadata and partial-book reporting must remain
bound to the failing world; do not discard it using an empty-world sentinel.
Public DResult and checker ABI2 already describe completed output and need not
change merely because internal checking becomes interleaved. Cache compatibility
is a separate question: source-only validated prefixes do not contain memo state.
Initially replay a general prefix through the same authority unless it carries
an explicitly validated world. Any special bound-Base skip requires its exact
identity and a measured proof; absence of instances in arbitrary prefixes cannot
be assumed. Do not silently reinterpret the current term cache format.

## Signature and sequencing ownership

- `infer`, `check`, their recursive workers and `KChecked` carry resulting world.
  `KEnv` carries world plus current owner/lhs/pending/quantities/unsafe/depth.
  `cb` remains the pure book projection used by normalization and comparison.
- `infer_ref` retains live/dead/generic and unfilled-law rules. After instantiation,
  compare the instantiated name against the current owner and check self descent
  on the residual runtime spine, matching pinned Ref order. Unsafe callers may
  not bypass a missing template body simply because ordinary missing laws can.
- `infer_app` consumes the returned comptime count before checking any runtime
  argument. Remaining applications sequence function then argument and return
  checked children. Closed arguments must not be checked twice.
- `both(check(a),check(b),...)`, telescopes, lambdas, constructors, parallel lets,
  matches and rewrites must explicitly sequence effects in pinned order. Preserve
  their existing quantity joins, contexts, substitution-stability fast paths,
  motive order and immutable numeric source ranges.
- `check_definition_result`, generic binder opening, and `dg_suffix_events`
  publish only completed original bodies and retain instances outside source
  event order. Opaque template-local constants must not leak into the outer world.
- Reuse canonical JSON keys, per-template ordinal, active memo identity and the
  exact 32768 UTF16/64-depth limits. Migrate instance installs to the existing
  persistent book API; no `Con`/`index_remove` on BookCache nodes.
- Diagnostic trace transport and the annotation pass need compatible internal
  interfaces. Host ABI2 completion still performs the existing final TODO check
  after actual checking; it must not re-specialize a completed program.

Expected compiler modules are check/kernel, check/specialize, diagnostic/trace,
relevant diagnostic producers, diagnostic/produce event transport, check/annotate,
and driver/api. Any host/cache or book API change needs its own explicit delta
and compatibility gate. No parser, core term representation or upstream edit is
required by the mechanism.

## Size, concept and cost bounds

The current kernel is 1215 physical lines, 108 definitions and 60 laws. The
specializer is 1047 lines, 104 definitions and 54 laws. A conservative kernel-only
lexical call graph finds 47 definitions reaching infer_template; cross-module
flows are not counted. Existing KChecked constructor/pattern/type occurrences are
7 kernel, 5 trace, 1 specializer. KEnv occurrences are 15 kernel, 4 specializer,
1 annotate. These are scope indicators, not exact edit estimates.

A named duplicate visitor family contains 29 definitions and 28 laws in 280
block lines, excluding unsafe markers. These may become removable only after
checked-output propagation replaces their work; canonical key encoding and
memo/cycle operations remain necessary. The implementation is therefore a broad
checker refactor rather than a two-function patch. A reasonable initial planning
range is hundreds of edited lines and several hours through focused validation;
full historical/backend/corpus/cost gates can extend that. No speed multiplier or
net line reduction is supported yet. The concrete possible gain is removal of
one full specialization walk and its erased type re-inference. The concrete
risks are larger result records, more environment transport, and retaining both
source and checked output for longer.

## Gates

The 22 frozen exact paired observations plus eight actual instance-name controls
are the first gate. Both deliberate diagnostic gaps must disappear without
changing their rejection phase, and all other exact rows and names must remain.
Retain both falsified original nested controls as useful quantity-order controls.
Then cover original source failure order, imported calls, law/fill visibility,
TODO versus instance failure, generic-local names, unsafe ordering, repeated and
interleaved memo hits, active cross-instance cycles, decreasing self reuse, and
both saved growth refusal positions. General prefix histories must preserve
instances or explicitly replay, including aliases and repeated imported sources.
Final promotion needs the full frontend vector, native/backend outputs and public
host/cache compatibility tests, followed by controlled whole-host timing. Probe
wall time is not compiler throughput evidence.
