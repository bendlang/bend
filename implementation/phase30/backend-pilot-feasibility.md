# Renew the retained backend pilot on the final image

Static feasibility review only; no compiler, backend or fixture was executed.
The retained 81-row Phase24 pilot is small enough to renew after final-image
selection. Seven historical candidate batches used approximately 119.3 seconds
of measured child wall time in total. Allow roughly 3–6 minutes including
attempt verification, startup and archive roundtrips, with a prospective
15-minute outer campaign cap. This is an estimate from older acquisitions,
not a current timing result or guarantee.

Use the unchanged `selfhost/tools/performance/phase24/backend-census.py`
`candidate` command, the retained `backend-plan-01/plan.json`, pilot indices
0–6, and the exact final14/15 attempt path. Give each batch a fresh directory.
The `candidate` path verifies the supplied attempt before and after acquisition;
the old API hash in the historical selection plan does not select the candidate.
Freeze the final attempt identity alongside the old selection/tool identities
in a new parent campaign plan before execution.

| Index | Batch | Rows | Historical child wall seconds |
| --- | --- | ---: | ---: |
| 0 | Later-emission check boundaries | 4 | 5.44 |
| 1 | Later-emission interpreter boundaries | 4 | 5.85 |
| 2 | Later-emission JS boundaries | 4 | 5.71 |
| 3 | Later-emission native boundaries | 2 | 4.48 |
| 4 | Positive interpreter namespace pilot | 24 | 25.70 |
| 5 | Positive JavaScript namespace pilot | 22 | 24.70 |
| 6 | Positive native C namespace pilot | 21 | 47.44 |

Totals are 28 interpreter, 26 JavaScript, 23 native and four checking rows.
The four boundary fixtures are `io/cid_unknown.bend`,
`io/effect_ctr_name.bend`, `io/main_foreign.bend`, and
`reg/array_open_element.bend`; only the latter two have native rows. Both
compilers historically accept all four during checking, then reject the
eligible execution/emission requests. Therefore the expected historical
outcome is **81 exact agreements, 77 execution passes, and four shared raw
check-oracle failures**. The check batch's `pass:false` must remain visible;
neither process exit zero nor exact agreement means 81 fixture passes.

Required retained inputs are present by filesystem inspection:

- The Phase24 selection/inventory and unchanged census helper.
- Pinned upstream checkout `018751270e800bc222a93dad7f257083ee53a5f7`.
- Node24.18.0 and the final attempt's frozen target harness, typed adapter,
  driver, API, runtime and Base; `verifyAttempt` checks their provenance.
- `phase16/wave6-backend-environment-01.json` and the retained Clang16 tree
  at `phase1/clang/root`. The CC symlink resolves to the original Clang binary.
  The environment also supplies CPATH, LIBRARY_PATH and LD_LIBRARY_PATH.

The existing helper uses isolated workers, four jobs, CPU3–6, 30 seconds per
probe, 4-GiB V8 heap, 4-MiB V8 stack and a 420-second outer limit per batch.
Both reference and candidate run freshly through the frozen paired harness.
There is no Bun/GPU/ThreadSanitizer/network expansion. The namespace selection
includes fixtures whose names mention those domains, but only the explicitly
listed interpreter/JS/native lanes run; do not silently add platform lanes.

Serialize all seven lane-homogeneous batches. Their fixture-local temporary
paths must not overlap another frontend/backend harness on the same sources,
and no clean performance window may overlap CPU3–6 work. A prospective
15-minute parent cap should stop and retain remaining unexecuted rows, rather
than letting seven individual 420-second limits silently expand the budget.
Stop for new incomplete or nonexact observations; distinguish the four already
documented shared check failures from new regressions.

The historical selected trees peaked near 45 MB for the native batch, with
earlier batches around 5–7 MB. The helper already creates a compressed archive,
verifies every regular-file hash by reading it back, and only then removes its
new duplicate tree. Preserve the final reports, logs, full vectors and archives.
Do not extract or modify old archives merely to rerun the sample. A refreshed
81-row result remains bounded backend evidence, not full backend conformance.

## Correction discovered by the fresh16 acquisition

The earlier estimate incorrectly called all77 execution rows passes. Direct
inspection of all seven historical raw reports shows **69 paired passes, eight
paired not-applicable compile refusals and four shared raw check failures**.
The eight refusals are the same four fixtures in JS and native lanes. Fresh16's
first60 rows exactly reproduce every complete historical observation, including
the four JS refusals; the overly strict campaign wrapper stopped before the21
remaining native rows. The original failed receipt is preserved. The explicit
[repair plan](../../design/phase30/backend-pilot-classification-repair.md)
reanalyzes those60 without changing verdicts and acquires only the remaining21.
This correction supersedes the77-pass prose above;81 exact observations never
meant81 fixture passes. Execution results belong in the separate renewal report.

## Final acquisition outcome

The checked16 pilot is now complete in the approved execution environment:
backend-pilot-recovered-16c/report.json preserves81 exact historical observations,
classified69 paired fixture passes,8 not-applicable compile refusals and4 shared
check failures. It reused60 verified rows and acquired only the remaining21
native rows in33.931 seconds. The initial classification failure and two
EPERM-bearing default-environment native acquisitions remain immutable. Minimal
pipe/file native probes passed in both environments, so no particular low-level
failure mechanism is established. This result is bounded81-row evidence and
does not include the optional811 new JS selection or release smoke.
