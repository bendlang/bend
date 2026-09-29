# Declaration checkpoints release

Installed source04 / `import-diagnostic-build-04`, API `40c8f7f3b7cd0e96aef57d7d574ebfd85607cd4e096909d083b450b4d973362c`,
genuine checked parent `2270973c76fb87cbcc684ad5ea4ed0222f4cba4340e0223b11932463e60eceed`, targets unchanged upstream
`b2111cf43244e65f76ddc278ee695e669f720cbf`. The [machine report](declaration-checkpoints-release.json)
binds the installed source, review, complete result comparisons and cost window.

Only `src/front/declarations.bend` changes: **17 additional physical lines,
one function and1,110 bytes**, with no new law, datatype, semantic state, host,
runtime, cache ABI or transformation. Source totals **15,897 physical /13,543
nonblank lines,577,003 bytes,59 modules,1,660 definitions,719 laws and67 types**.
Phase19's single live checker and exact-prefix repair remain installed. The
larger contextual parser is still private.

## Behavior and independent challenge

Pending `@unsafe` reports the pinned structured expectation for `def`. A datatype
constructor begins at a name head, with `def`/`type`/`law` ending that loop;
indentation and immediate lookahead for `{` no longer decide constructor admission.
The shared owner validates name, import alias, duplicate name and opening brace
in that order. Whitespace/comments are accepted there, semicolons are preserved
for rejection. The datatype loop hands its already-spaced cursor to `f_top`.
Global semicolon handling is unchanged.

Match heads and row patterns require their first term before accepting `:` or
skipping a comma. Two constant-time `List.is_empty` checks enforce that boundary.
Later optional commas keep the pinned behavior. No growing-list count, separate
parser or diagnostic rewrite is added.

Independent review caught an intermediate false acceptance: source02 used
`f_skip`, which also consumes semicolons. Its15 newly false-accepted observations
and9 inherited adjacent acceptance observations are retained across raw/supplied/
host routes. Source04 uses existing `f_space` at the brace and both datatype-loop
feeds, and calls `f_top` on loop exit. Source02/03 were never installed. See the
[owner report](import-diagnostic-final.md) and [review](declaration-checkpoints-review.md).

## Validation

| Selection | Earlier exact | Final exact |
|---|---:|---:|
| Maintained development controls |34/36|36/36|
| Decorator/import boundaries |4/24|24/24|
| Constructor name/brace boundaries |18/50|50/50|
| Match first-element boundaries |42/54|54/54|
| Expanded datatype whitespace boundaries (source01) |6/44|44/44|
| Original broader group selection |128/196|136/196|

These are overlapping observations and routes, not disjoint program counts.
Original supplied39 and ordered-host43 have zero strict differences. Three new
positive programs pass check/interpreter/JavaScript/native comparisons (**12/12**)
and produce41/42/43; see [execution evidence](declaration-programs.md).
All **42 installed/relocated CLI checks** pass.

The main2996-result vector is unchanged in its entirety; its two known do-block
first-diagnostic differences remain. The broader196 has exactly eight changed
parse/check observations across four saved empty-head fixtures, all newly exact,
with no lost match or changed reference result. Six also correct primitive
acceptance evidence. It retains60 strict differences and three failed fixture
verdicts (monad check and grouped body-comma parse/check).

Raw harness flags remain unchanged: the grouped runner is incomplete/false after
its strict selected-completion assertion, despite all196 observations collected
without worker failures/timeouts. The main raw vectors retain their same five
fixture verdict failures. Acquisition, pinned agreement and strict fixture
contracts are separate axes; the independent regression audit does not relabel
these reports. Earlier backend41, literal20, chronology22 and memo/history gates
remain evidence for Phase19; they were not all rerun or relabeled as Phase20.

## Controlled cost and iteration loop

Fresh CPU0 processes run serially TS/B/C/C/B/TS on identical final source, with
4 MiB stack/4 GiB heap and all other compiler/probe/hash/archive jobs held.
All35 host files, Base, runtime, pin and version5 transformation are unchanged.
Bend uses separate validated Base caches; TypeScript checks Base. OS caches were
not flushed. No program emission is timed; all six type/trust observations and
unsafe-definition sets agree.

| Image | Mean process seconds | Mean request seconds | Peak RSS KiB |
|---|---:|---:|---:|
| TypeScript |3.4463|2.3723|478512|
| Installed Phase19 baseline |10.9727|9.8585|655168|
| Phase20 candidate |10.9412|9.8370|658024|

The process difference is **0.29% lower**;
request difference **0.22% lower**, peak RSS
**0.44% higher**. This is
**neutral**, not a new speedup claim. The same-window TypeScript gap is
**3.1839→3.1748×** (about3.17×).
Two samples per image do not establish a general performance improvement.

The final checked build took16.70s and maintained36 validation
16.64s: **34.68s**
from build start through focused validation. That is one observed edit loop,
not a controlled benchmark; broad regression, execution and cost gates ran once
the candidate was coherent. No new full self-reproduction was required.

## Retained integration failures and next boundary

Audit01 wrongly equated the raw `complete` flag with acquisition health; audit02
compared candidate-only host metadata with absent TypeScript metadata. Audit03
checks the unchanged paired behavior protocol against raw data, plus complete
old/new candidate payloads and acquisition/identity health. No fixture or oracle
changed. Promotion01/02 copied zero files; their tooling assumed different
identity/API report schemas. Promotion03 verifies each actual schema and installs
one file. Original tools and reports remain alongside the successful attempts.

The next bounded [group-boundary design](../../design/phase21/group-boundaries.md)
tests a first-binder source-range correction for three remaining observations.
The two grouped-comma acceptance differences require preserving completed-group
and error order; a raw tag guard would reject a valid nested tuple. Do not add
flattener changes that have demonstrated no gain on the remaining60.

Root commits this usable release locally. Remote publication remains blocked by
the earlier automatic approval review; no push success is claimed. Full conformance,
independent proof-kernel/GPU coverage and a new self-hosted fixed point remain open.
