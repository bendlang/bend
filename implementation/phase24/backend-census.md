# Phase24 current-image backend census and two emission repairs

The fresh pilot found two real gaps that frontend agreement cannot detect: a
foreign definition could share its name with a constructor and still execute,
and valid distinct function names could collide in native C identifiers. The
final combined compiler fixes both with eleven net production lines, one helper,
no new representation, and no runtime change.

This is a bounded backend sample, not full backend conformance. The installed
Phase23 API `5596f914fd245a5085a614b81099360aeaf601ed61f16357fc491c85106c1102`
was measured before edits. The final checked candidate is
`7b523bdffc0acde702dda1005a5e8201f7b65b2e432d1be95b07f2cfcc0346fa`, in
`selfhost/build/phase24/combined-build-02`. Both target upstream
`018751270e800bc222a93dad7f257083ee53a5f7`.

## Inventory and acquired scope

The maintained inventory finds 1,513 runnable fixtures and 11 supporting Bend
modules, or 1,524 Bend sources. There are 1,016 positive and 497 negative fixtures;
999 positive fixtures have a main. Positive execution eligibility is:

| Lane | Eligible positive observations | Pilot acquired |
| --- | ---: | ---: |
| Interpreter | 999 | 24 |
| JavaScript | 833 | 22 |
| Native C | 812 | 21 |
| Total | 2,644 | 67 |

Twenty-three fixtures are potential GPU cases per device lane; no GPU observation
is acquired here. Eligibility says the harness can select a fixture, not that its
host environment or compiler capability is sufficient.

Four existing fixtures expect rejection after checking: `io/cid_unknown.bend`,
`io/effect_ctr_name.bend`, `io/main_foreign.bend`, and
`reg/array_open_element.bend`. They contribute ten eligible execution rows and
four check rows. The pilot therefore contains **81 rows: 67 positive executions,
ten later-emission executions, and four checks**. The four checks accept in both
compilers; their original later-emission fixture oracles remain raw failures.
They are exact observed agreement, never relabeled as passing rejection tests.

The positive pilot takes the deterministic middle fixture of each of 24
namespaces, preferring sources no larger than 2,500 bytes. The complete inventory,
selection policy and prospective scope are frozen in
[the census design](../../design/phase24/backend-census.md),
`selfhost/build/phase24/backend-inventory-01` and `backend-plan-01`.
The unexecuted broader 64-row batches remain a future plan. Once this sample
found actionable compiler defects, the coordinator prioritized their correction
instead of maximizing the number of acquired rows.

## Observed before and after

| Group | Released Phase23 exact | Final candidate exact | Final fixture verdicts |
| --- | ---: | ---: | --- |
| Later-emission checks | 4/4 | 4/4 | 4 unchanged raw failures |
| Later-emission executions | 8/10 | 10/10 | 10 pass |
| Positive executions | 66/67 | 67/67 | 67 pass |
| Entire pilot | 78/81 | 81/81 | 77 execution passes, 4 check failures |

Every final pilot acquisition finished with unchanged registered inputs and
artifacts; no timeout or harness error occurred. Both compiler sides were run
fresh. Individual reports retain status, phase, checked/type-acceptance flags,
proof trust, diagnostics, exit code and output, not merely a summary count.

The two distinct defects explain three differing rows:

- `io/effect_ctr_name.bend`, interpreter-IO and JS: upstream rejects with
  `Tick names both a constructor and a foreign def: name one apart`; Phase23
  instead prints `7` and exits successfully. The new shared driver validation
  gives the exact compile rejection while check-only behavior stays unchanged.
- `import/js_names_apart.bend`, native: upstream prints `22`; Phase23 rejects
  with `native identifier collision: FID_HAS_HYPHEN_LIB_TWO`. The new injective
  function ID mapping prints `22` and preserves distinct source names.

The original failures are retained in `backend-pilot-01` through `-07`; final
reruns are `backend-candidate-pilot-01` through `-07`. These are concurrent
correctness runs on CPU3–6, not comparative speed samples.

## Minimal implementation and review correction

[P24-003](../../experiments/phase24/P24-003-effect-collision.md) places the foreign
name check in `driver_emit_owned`, after the existing fixed runtime-owned names.
It inspects the whole book before reachability and reuses `j_find_ctor` and the
existing `Foreign` term. An unused foreign collision must still reject upstream;
checking only emitted reachable definitions would be incorrect. Pure interpreter
normalization and check-only requests retain their existing earlier return.

The first candidate used eager Boolean conjunction before constructor lookup.
Independent coordinator review identified that this would scan the book for
ordinary nonforeign definitions too. Candidate01 and its exact bytes remain
preserved; candidate02 uses the existing lazy `kc` branch, so only actual foreign
definitions search constructor names. There is no new index/cache/representation.

[P24-005](../../experiments/phase24/P24-005-native-identifiers.md) changes `nt_fid`
to reuse `nc_ctor_codes`, already used to distinguish native constructors. The
`FID_` prefix followed by underscore-delimited decimal Unicode scalars is
injective across case and punctuation. `MAIN_FID` now calls the same mapping.
Fixed runtime identifiers (`FID_IO_EMIT`, `FID_EXIT`, `FID_ENTER`, and
`BEND_CLO_APPLY`) stay unchanged and are disjoint from this digit-prefixed encoding.
Constructor IDs and their external/runtime ABI stay unchanged. Foreign C symbolic
`FID(name)` uses the common mapper; no direct user FID literal contract was found
in the pinned C fixture sources. The old native unit fixture that required a
collision rejection is replaced by an execution control for these distinct names.
The historical native unit script was subsequently rerun in an isolated minimal
copy, after correcting its missing shared-scanner module and current List
constructor descriptors; the complete outcomes are detailed below.

Reusing the encoding increases emitted C text: the identical `base/nat_ops.bend`
pilot produces 220,154 bytes before and 269,190 afterward (+22.27%); the pinned
reference remains 78,271 bytes. This is a source-size tradeoff, not a measurement
of native compilation time, binary size or runtime speed. No generated-program
speedup is claimed. Ordinary compiler performance belongs to the coordinator's
separate exclusive cost experiment. The independent storage agent's
[read-only review](backend-patch-review.json) found no blocker in full-book
validation, first-error precedence, identifier injection or foreign substitutions;
that review did not independently execute the controls.

## Focused controls and remaining scope

Direct book controls in `selfhost/tests/phase24-backend/ownership-controls.mjs`
pass 11/11 against the final checked API. They cover empty/foreign-only/constructor-
only books, declaration ordering, exact qualified and case-sensitive names,
ordinary nonforeign definitions, reserved-name error precedence, the first
foreign collision, and a foreign declaration carrying Base provenance.

The source controls in `selfhost/tests/phase24-backend/fixtures/` add used, unused
and qualified collisions; successful renamed and qualified-distinct effects;
dot/underscore/case/runtime-looking native function names; and actual foreign C
symbolic FID references. Their paired before/after acquisitions are preserved
under `backend-focused-run-*` and `backend-focused-candidate-*`. The initial final
acquisition is27/28 exact: seven check rows and20 of21 execution rows. Three
check rows retain matching later-emission oracle failures. The remaining native
foreign-FID fixture is an invalid positive control: both compilers remove the
constant functions' callable segments, then C compilation fails on undefined
FID macros. Different names/paths make that pair nonexact; neither raw failure
is relabeled. [The prospective v2 control](../../design/phase24/backend-controls-v2.md)
retains recursive calls and specifies the bounded repair. That v2 then exposed an
affine mistake in the test itself: the IO result was consumed twice, and both
compilers rejected it identically. The retained [v3 repair](../../design/phase24/backend-controls-v3.md)
composes those recursive functions and consumes the input once. It passes4/4
exactly, including actual native C execution and unchanged foreign macro text.

The final focused scope in `final-controls.json` is28/28 exact with21 execution
passes and seven matching checks (three raw later-emission oracle failures).
This is explicitly assembled from the original successful six fixtures and the
four new v3 rows, not a claim that the initial28-row acquisition passed. Original
constant-FID and affine-v2 failures stay visible in their own attempts. The
[machine-readable summary](backend-census.json) links every report/hash and
records the composition.

The maintained native unit script initially failed because its scoped assembly
omitted core/reach.bend, which now supplies KF_Source; adding that existing module
revealed missing synthetic List Nil/Con descriptors required by the runtime's
io_list helper. Both failed attempts01/02 remain retained. Attempt03 passed all22
native execution cases at one and four threads, four diagnostics, one actual
foreign dispatch, and6,006 independent Nat decision-chain comparisons. Its
27 PASS lines are authoritative: the old printed total still added six diagnostics
and said28. The final edit corrects only that display arithmetic to add five; a
byte comparison proves the tested assertion/compilation/execution body is
unchanged. The exact pre-display-correction script is preserved inside the
attempt03 minimal project. This suite builds a separately checked scoped API
from frozen production source; it does not constitute another installed full
compiler build.

The separate [environment report](backend-environment.md) records the Bun/Node
TCP ablation and operational Clang16 ThreadSanitizer probes. Those observations
must retain their exact host/compiler/program identities; they are not silently
folded into this pilot or promoted to universal race safety. Runtime code was
unchanged throughout these repairs. Full remaining backend coverage, arbitrary
structural/atomic races, independent kernel checking and GPU execution remain
outside the result established here.

## Reproduction and preservation

`selfhost/tools/performance/phase24/backend-inventory.mjs` freezes the inventory;
`backend-census.py` freezes the selection and runs the unchanged maintained paired
harness. The `candidate` command verifies the frozen checked attempt before and
after each batch. Each execution uses isolated workers, Node24.18.0, retained
Clang16 environment, 4 MiB stack, 4 GiB heap, 30-second probe limit and CPU3–6.
Lane-homogeneous batches prevent two modes concurrently using the same fixture's
fixed temporary paths. No timeout increase or generated-code patch was used.

```sh
python3 selfhost/tools/performance/phase24/backend-census.py candidate \
  selfhost/build/phase24/backend-plan-01/plan.json pilot 0 NEW_OUTPUT \
  selfhost/build/phase24/combined-build-02
```

Repeat pilot indices 0–6, each with a new output directory; focused controls use
`selfhost/tests/phase24-backend/final-controls.json focused 0` through `3`. The
original controls and v2/v3 selections remain retained for exact historical replay. The `run`
command acquires the pinned installed Phase23 baseline and refuses an unexpected
API identity. The historical baseline release is required after promotion.

Every acquisition keeps its consumed helper, exact configuration/command,
registered identities, original logs, full paired and individual result vectors,
and emissions. Compressed selected trees are read back and every regular file's
SHA256 compared before removing only that new duplicate tree. `archive.json`
records the complete roundtrip inventory and compressed archive hash. Source
before patch01 and the eager-lookup intermediate before patch02 are retained;
helper versions consumed by distinct acquisitions remain retained too. Durable
capsule/recovery evidence is owned by the coordinator and linked from the phase's
main implementation report. An ignored build path alone is not preservation.
