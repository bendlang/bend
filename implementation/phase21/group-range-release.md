# Phase21: grouped-local and typed-annotation origins

The installed compiler now preserves the first binder's source location for a
local binding and the original parser cursors for a typed binding's generated
annotation. The broader saved suite improves **136→139 exact observations out
of196**, with three gains and no lost matches. The complete main2996 result
vector is unchanged, including its two remaining do-block diagnostic differences.

The final source is `group-range-source-02`, checked attempt
`group-range-build-02`, derived API
`44094e58cb0ef033e2c08c2827565e859c3594b3136868d4f821262145aea7f0`.
Its genuine checked parent, source digest, final gate identities and installation
are recorded in [the machine-readable report](group-range-release.json).
Upstream remains `b2111cf43244e65f76ddc278ee695e669f720cbf`.
The prior usable release is [Phase20](../phase20/declaration-checkpoints-release.md).

## What changed and why

`f_let_body` previously constructed an unlocated raw `Local`. Parenthesizing it
caused the parser to fill its absent range from the entire group. Later lowering
preserved that range, so errors pointed at a whole expression rather than the
binder selected by the pinned compiler. Its successful constructor now uses the
existing pattern's range; the child-error branch is unchanged.

The first one-expression candidate exposed a second dependency. `f_locate`
stops descending into an already located term, so the generated `Ann` of a typed
local lost its inherited range. That candidate gained the intended observations
but was withheld after the complete-graph review found this loss. Source01 and
all its reports remain preserved, including its apparently successful narrow
controls. It was never installed.

Source02 repairs the location at the existing annotation producer. The original
body start travels through `f_statement`, `f_typed_let_try` and `f_let_ann` as
one additional U32 argument per worker. The annotation end comes from the
returned, spaced parser cursor. This matches the pin even with parenthesized
binders, a grouped RHS, comments or astral Unicode characters. Neither endpoint
can generally be recovered from a child term's range.

Only `front/declarations.bend`, `front/parallel.bend` and `front/sugar.bend`
change: **+3 physical/nonblank lines, +156 bytes**, no new function, law or type.
There is no new traversal, pattern classifier, semantic state, host change,
cache change or transformation profile. The maintained59 modules total15,900
physical /13,546 nonblank lines,577,159 bytes,1,660 definitions,719 laws and67 types.
The earlier all-`.bend` directory census also counted two non-manifest modules;
the published count uses the unchanged canonical module manifest.

## Validation and its limits

| Gate | Final result |
| --- | --- |
| Genuine checked build plus maintained selection | 36/36 strict exact |
| Original broader196 | 139 exact,57 differences; three gains, zero losses |
| Full frontend2996 | Every complete result payload unchanged; two diagnostic differences remain |
| Independent original68 controls | 44→60 exact;16 gains, zero lost matches or primitive changes |
| Additional typed RHS/EOF4 | Two exact; two inherited diagnostics unchanged; no host range failure |
| Complete raw/lowered graph observations | 172; zero nonrange or acceptance changes |
| Indexed annotation coordinates | All30 positive raw/lowered observations exactly match pinned annotation, RHS and type ranges |
| Legacy unindexed observations | All80 retain absent0/0 ranges |
| Actual program observations | 12 exact across check/interpreter/JS/native, including nine successful executions |
| Installed and relocated CLI | 42 checks pass |

Suites overlap; these counts are not distinct programs to be summed. The three
saved196 gains are `group/local-pattern` parse/check and `group/local-callee`
check. The latter's parse result stays accepted. Raw broader196 still fails its
strict suite gate; the separate healthy-collection/no-regression audit does not
turn the remaining57 differences into passes.

The new independent controls retain mistakes in prospective fixture assumptions.
Six original acceptance expectations disagreed with actual pinned behavior.
Two supplemental constructor-group fixtures expose four inherited false
acceptances. An initial `//` comment tested a syntax error rather than Unicode;
a separate frozen `#` cohort supplies the actual UTF16 test. Source02's additional
typed-error controls retain two wrong diagnostics already present in the parent.
See [the independent controls](group-range-controls-source02.md),
[structural review](group-range-structure.md) and
[source review](group-range-review-source02.md).

The three execution programs print41n,42n and43n identically in both compilers.
The original `#|` comments mistakenly omitted `n`, so their raw report retains
nine failed output expectations per compiler, despite healthy execution and
exact agreement. The observation audit checks the actual outputs without editing
the fixtures or rerunning identical code. Its first version assumed persistent
workers and failed on the correctly isolated worker schema; the second explicitly
validates isolated mode. Both audit versions and the original raw failure remain.
This is twelve exact compiler observations, not twelve passing original oracles.

The independent source review approved the corrected bounded gate. Root then
compared full old/new result vectors, checked all214 source/host members and
the protected75 unrelated Phase6 file hashes and git states. Promotion copied
exactly three source files and installed the verified checked derivative;
the original checked image and prior release lineage remain available.
Older backend41, literal20 and request-history gates retain their earlier release
scope; they are not silently relabelled as Phase21 executions.

## Controlled cost and iteration speed

The exclusive same-source order was TS/B/C/C/B/TS, fresh CPU0 processes,
4MiB stack and4GiB heap, with all other experiment jobs held. All35 host files,
Base, runtime, upstream pin and guarded version5 profile agree. Each Bend image
uses its own validated Base cache; TypeScript checks Base. OS caches are not
flushed. This measures checking/trust reporting, without emission.

| Compiler | Mean process seconds | Mean request seconds | Peak RSS KiB |
| --- | ---: | ---: | ---: |
| Pinned TypeScript | 3.4364 | 2.3647 | 476,440 |
| Phase20 parent | 11.0060 | 9.9052 | 655,860 |
| Phase21 final | 10.9547 | 9.8612 | 655,108 |

The same-window gap is3.2028→3.1879×. Process time falls0.47%, request time0.44%
and peak RSS0.11%. With only two samples per image this is a **neutral cost
screen**, not a new speedup claim. Do not combine this ratio with older windows
or claim faster emitted programs. One observed checked build plus36-control loop
took35.17seconds in the concurrent development environment; it is not a controlled
iteration-speed benchmark.

## Next semantic boundary

The separate [comma investigation](group-comma.md) collected60 healthy
observations,39 exact and21 differences. It confirms that a raw Local/Match comma
guard would reject valid completed inner groups and can hide an earlier pattern
error. It also found a missing grouped-Parallel lowering route, but adding that
dispatch alone could make an invalid raw-comma form pass checking. That shortcut
is therefore deferred.

The next semantic work must preserve group completion and the first-error order
with actual lexical context. Do not add a second pattern checker or infer a
completion boundary from source ranges. The private contextual parser remains
research evidence, not installed production functionality. Main do-block errors,
broader parser gaps, full-language conformance, independent proof validation,
GPU execution and the50%/75% source-reduction targets remain open.

The [design](../../design/phase21/range-execution.md) and its
[typed-annotation correction](../../design/phase21/typed-annotation-origin.md)
were frozen before their candidate work. Evidence preservation and independent
byte recovery are recorded separately in the
[preservation index](../../experiments/PRESERVATION.md). Commits are local;
remote publication remains blocked by the earlier automatic approval review.
