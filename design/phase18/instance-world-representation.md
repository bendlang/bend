# Phase18 stage1: checker world representation cost ablation

Prospective, isolated representation/transport experiment, authorized after the
Phase17 [witness report](../../implementation/phase17/instance-chronology.md).
Parent source is `selfhost/build/phase17/find-worker-source-01/project`; the
parent's eight-line frontend find worker is retained exactly. No live source or
Phase16/17 input is edited. Root reviews this contract before any checked build.

## Question and falsification

Can the existing checker carry the world needed for future live instantiation
without unacceptable whole-host time/memory cost or changed behavior? This stage
introduces the records and faithfully transports their current state, but does
not mint instances during normal checking, change child evaluation order, consume
comptime applications, reconstruct checked output, or remove the specializer.
Both measured chronology gaps must remain byte-identical to the parent.
A representation result alone cannot establish that later state effects are
correct, or that the complete refactor is faster/smaller.

Reject or revise this candidate on any changed complete result/diagnostic,
incorrect world at failure, lossy memo/fresh transfer, new demand for an irrelevant
book/body, source-body mutation,
unknown checked provenance, or material unexplained controlled cost increase.
Cheap shape/equivalence controls precede any coordinated timing window.

## Exact internal records

```
KWorldFresh = KFreshKnown { next: U32 } | KFreshDeferred {}
KWorld { book: List<KDef>, memo: List<KSpecMemo>, fresh: KWorldFresh }
KEnv   { world: KWorld, name, lhs, pending, quantities, unsafe, depth: U32 }
KChecked { term, typ, uses, error, world: KWorld, consumed: U32 }
```

Existing fields keep their meaning/order; KEnv replaces its first book field and
adds depth last. KChecked appends world and consumed to the old four fields.
KWorld has no error field: KChecked owns first failure, so KSpecState.error may
contain KChecked without a recursive error/world representation. Source bodies
stay in the existing semantic book. No checked-output accumulator is added yet.
KWorld.book is an immutable reference, not a copied list or reserialized book.
KEnv grows from six to seven fields; KChecked from four to six; KWorld is one new
three-field type and KWorldFresh is one explicit two-constructor type. The known
case carries the already available next-ID value; deferred carries no value.
Those payload counts are operation estimates, not memory data.

Use projections `cw(e)` for environment world, `cd(e)` for depth, `rw(r)` for
result world, `rx(r)` for consumed applications, and `kw_book`, `kw_memo`,
`kw_fresh` for world fields. Existing `cb(e)` projects through cw and kw_book.
World construction belongs to public checker entry or existing specializer
bridges, not every recursive infer/check call. Ordinary public entry initializes
KFreshDeferred without inspecting the book, even its first node. Only a caller
that already owns a validated bound through existing work may construct Known.
The specializer already knows its actual next-ID value and memo; its bridge
uses those without a new scan, default value or reset. Stage1 never resolves
Deferred. Any future mint must include the owner body and temporaries in its
freshness proof; a book-only bound is not assumed sufficient for arbitrary
private/public checker entry. This explicit extra state avoids both a magic zero
and new demand for poisoned or irrelevant book bodies. It adds another metadata
allocation/type/concept, which the report counts.


## Faithful propagation in this stage

- `ok`, `bad`, `dg_bad_detail`, `dg_bad_message` receive an explicit world. There
  is no empty-world sentinel for failures. Even `bad("")`, the existing empty
  success sentinel, receives the actual world of its caller.
- `checked(r,...)` preserves rw/rx; `both(a,b,...)` retains the first failure
  unchanged, otherwise carries the last successful result's world/count.
  Existing eager argument evaluation remains unchanged. This is valid only for
  this no-new-effects stage; stage2 must explicitly sequence child worlds before
  enabling live instantiation.
- Trace accumulation, unrestricted-binder notes, quantity errors and template
  diagnostic adaptation preserve the originating result's world/count. A new
  failure derived from a completed check uses that check's world, not a stale
  enclosing environment. Leaf failures use their real environment world.
- `lhs_step`, matcher lhs rebuilding and constructor environments reuse world
  and depth. Generic binder opening may create a temporary book; its world
  retains memo/fresh and the actual temporary source declarations. An error in
  that scope keeps this actual failing world. A successful public definition
  check restores the caller's book view, preserving memo/fresh, so opaque generic
  constants cannot escape. It does not overwrite a failure world.
- A world-aware internal definition entry accepts world and depth. Existing
  public book-based entry signatures remain wrappers. Specializer validation
  enters through that internal interface with actual memo/fresh and instance
  depth; the existing prewalk and subsequent validation order are unchanged.
- Every consumed count is zero here. No skip branch is added to infer_app and
  no instance output is substituted into its result. Direct controls nevertheless
  verify result and trace reconstruction preserves a supplied nonzero count,
  so the representation does not silently discard a field.
- DResult, public host APIs, term/span/check ABIs, term cache format, frontend,
  generated-runtime helpers, runtime and the maintained version5 derivative
  stay unchanged. New internal result records are not a public cache payload.

Expected edits are confined to check/kernel.bend, check/specialize.bend,
check/annotate.bend, diagnostic/trace.bend and diagnostic/produce.bend. A sixth
module is allowed only if source inspection exposes another internal consumer;
record it explicitly. No separate checker or alternative error renderer is added.

## Cheap controls and attribution

Freeze each numbered source preparation and exact parent-relative patches before
building. First use the genuine checked B1 workflow plus its default 36 focus
observations on CPU1. Reuse the unchanged Phase17 22 paired witnesses and eight
public ABI2 materialized instance-name controls. Compare the entire parent and
candidate records, including diagnostic/trust/unsafe axes, rather than only
acceptance. The two known diagnostic gaps remain strict differences against TS;
zero differences against the parent is the stage1 contract.

A named probe extension may expose internal projections/constructors after a
checked build only if production API bytes remain its exact prefix and target
functions are bound by hash. Preserve a separate probe identity. Direct controls
compare old term/type/uses/error payloads, verify real world-book/memo/fresh/depth
transport, first-error retention, note/trace rebuilds, successful generic scope
restoration and failed generic context retention. Include poisoned/unneeded plain-book bodies, empty-book and exact-prefix
contexts. Include nonempty memo and
nonzero consumed/depth sentinels as transport values, never as a claimed semantic
instantiation implementation. The production export list stays unchanged.

Count exact changed physical/nonblank lines, bytes, definitions, laws and types,
including every helper. Report the new world concept and retained KSpecState
bridge as additional complexity, not simplification. Preserve failed builds,
resource limits, strict differences and all consumed tool versions.

No exclusive timing is run without root coordination. If the cheap gates pass,
measure fresh processes against the exact find-worker parent, with identical
source, host/caches, resources and TS controls. Compare complete CLI checking and
trust reporting, including the old specializer. Time inside one newly shifted
boundary is not a whole-compiler speed estimate. No promotion or stage2 semantic
migration is authorized by this experiment.
