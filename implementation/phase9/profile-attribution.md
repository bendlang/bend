# Phase 9 baseline freshness attribution

The existing Phase 8 release07 CPU profile attributes **77.743 seconds of sampled freshness work (33.662% of the complete sampled profile)** to chronological declaration checking. This supports fixing the missing chronological-book cache before undertaking a larger checker rewrite. It does not predict an equal wall-time saving: other work, added cache maintenance, and sampling overhead remain.

| Exclusive sampled function | First meaningful caller | Sampled seconds | Share of that function | Share of complete profile |
| --- | --- | ---: | ---: | ---: |
| `norm_max_term` | `compare` | 68.608187 | 98.711% | 29.707% |
| `norm_max_defs` | `compare` | 9.176223 | 98.540% | 3.973% |
| `norm_max_term` | `dg_suffix_events`, looking above `compare` | 68.566599 | 98.651% | 29.689% |
| `norm_max_defs` | `dg_suffix_events`, looking above `compare` | 9.176223 | 98.540% | 3.973% |

These are two alternative views of the same samples; the rows must not be added together. The chronological worker accounts for 98.63768% of the two target functions' combined 78.816556 sampled seconds. The complete denominator is 230.952175 sampled seconds, including startup, garbage collection, and other functions. These are sampled CPU time weights, not call counts, allocations, or a controlled compiler speed ratio.

The retained physical stack provides a concrete source explanation. In frozen release07, `dg_suffix_events` calls `event_error(seen, ...)` (`diagnostic/produce.bend:202`; generated API line 1413). The law-fill branch compares old and new signatures (`check/kernel.bend:969`; generated API lines 2880–2883). `compare` eagerly obtains a fresh binder bound before `norm_compare` (`core/normalize.bend:158`; generated API line 4778). The chronological `seen` list starts empty without a `BookCache`, even though the separate declaration context is cached (`diagnostic/produce.bend:123`). Consequently `norm_book_bound(seen)` falls back to traversing preceding definitions (`core/normalize.bend:261–270`). A representative retained stack is `norm_max_term → norm_max_defs → norm_max_book → anonymous closure → compare → anonymous event_error closure → dg_suffix_events`. The named caller attribution alone does not distinguish every operand scan from a whole-book scan; the `norm_max_defs` ancestor in this witness and the separately measured `norm_max_defs` cost establish that whole-book scans occur here.

The analyzer streams the original 1,573,317,008-byte profile once and retains node-to-parent and node-to-frame IDs as unsigned 32-bit arrays. It skips anonymous and pseudo frames, the explicit runtime set `run_loop`, `run_tail`, `run_clo`, `run_lib`, `run_jump`, names beginning `$norm_max`, and the freshness wrappers `$norm_book_bound$` and `$norm_bound_found$`. The second view additionally skips `$compare$` and `$norm_compare$`. Generated trampoline execution can erase logical callers; the result describes physical sampled ancestry, with representative node/frame IDs retained for inspection.

The original raw profile SHA-256 is `05e62a8dad989161a2d117c17d8beaaa00508c796a136ac475a9bc18cbd3dd33`. It contains 6,821,613 nodes and 207,861 samples. One original sample delta is −11 microseconds. An initial instrumentation attempt rejected this signed delta; its source and traceback remain preserved. The successful parser retains signed weights exactly, matching the original streaming summary rather than clamping or reordering. Attempt 02 completed in 55.25 seconds; attempt 03 reused its arrays to add the second attribution view. Synthetic controls test skip behavior, weighted attribution, and unattributed roots. A separate reconciliation verifies both target totals, node/sample counts, profile identity, and complete time denominator against the earlier streaming summary.

The maintained tool is [profile-callers.py](../../selfhost/tools/performance/phase9/profile-callers.py). Original results, both successful attempts, rejected source/traceback, frame tables, arrays, sample metadata, source identities and reconciliation are under `selfhost/build/phase9/profile-callers-01/`; the final result is `attempt-03/report.json`. The Phase 9 evidence archive will preserve these artifacts after producers close. No compiler was rerun and no production compiler source was changed for this investigation.

## Independent review of the resulting cache proposal

The attribution owner separately reviewed the other agent's chronological-cache
proposal. Its empty persistent cache seeds independent declaration and event
contexts; it does not expose future declarations through chronological lookup.
Only the conservative full-source binder bound is shared. Both ordinary and
validated-prefix paths retain the original worker and exact-prefix fallback.

The first proposal had a real raw-API regression: an empty constructor name was
mistaken for the cache's empty-named index node. The preserved
`chronological-cache-01/controls-01/report.json` records the changed verdict.
The corrected proposal excludes `BookCache` metadata from the constructor scan
and otherwise keeps its lookup and recursion. Read-only review of actual checked
candidate 02 confirms 14/14 complete diagnostic results match the baseline,
including that witness, and 40/40 selected public observations pass; its separate
component report also passes. The instrumentation report
`chronological-counts-03/report.json` records one full-book scan for each 4/8/16
law-fill workload after the correction. This establishes the intended mechanism
on those workloads, not a full-source wall-time result.

No static blocker remains for real declaration records plus reserved internal
cache metadata. Arbitrarily forged raw `KDef` records that claim the internal
`BookCache` kind are outside this review's equivalence conclusion. Integrated
conformance and controlled timing remain separate phase gates.
