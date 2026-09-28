# Phase13 structured rewriter

Work in progress under the [prospective design](../../design/phase13/structured_rewriter.md).
Phase12 remains the installed baseline until a new artifact earns promotion.
The fresh profile, byte-identical structural refactor, explicit-worker pilot,
independent demand/stack controls, full-source measurements and promotion decision
will be reported separately. No new performance or conformance result is claimed.

## Fresh released-compiler profile

Installed release verification and unchanged Phase9 diagnostic profiling pass.
The compiler is Phase12integrated-03; Node24.18.0, CPU0,4MiB stack,4GiBheap,
10ms samples. Initial parallel work was static. Raw profile is56,402,488bytes,
SHA-256`0b78df312769c3c98b1f5b57707128a38ee884de9dc605620bdc3cd99cf7b6e7`,
with2,698samples. Complete evidence is `selfhost/build/phase13/current-profile-01`.
The unchanged Phase10 lexical-owner tool attributes exclusive samples to their
enclosing generated functions; runtime/GC remain separate, not attributed to
hypothetical callers or claimed recoverable savings.

| Lexical owner | Exclusive sampled time |
| --- | ---: |
| `run_loop` | 14.55% |
| `(garbage collector)` | 13.47% |
| `$norm_eval_node$` | 4.72% |
| `$lookup$` | 4.54% |
| `$index_find$` | 3.83% |
| `$check_node$` | 2.92% |
| `$check_ctr_found$` | 2.78% |
| `update` | 2.48% |
| `$subst$` | 2.34% |
| `$core_subst_stable$` | 2.16% |
| `$norm_match$` | 2.04% |
| `$index_remove$` | 2.03% |
| `$check$` | 2.02% |
| `$f_find$` | 1.85% |
| `$ffw_kids$` | 1.45% |

The instrumented 28.884s process is excluded from speed ratios.
This supports testing hot branch families, but establishes no future speedup.

## Compatibility and baseline controls

The experimental shared representation reproduces the authentic version 1–5
API bytes and exact serialized transformation statistics. This includes source
offsets and skipped-site records, which the derivation verifier treats as part
of the contract. Evidence: `selfhost/build/phase13/rewriter-stage1-01/report.json`.
This is a compatibility result, not a reduction in maintained code: the prototype
still depends on the frozen scalar/provenance implementation.

Independent baseline calibration also passes the fresh 6,000-character string
and both exact 53/60-request histories. Every one of the 113 historical results
matches released Phase12; the old 53rd request's seed-regression failure remains
recorded separately from the required successful current-release oracle. Evidence:
`selfhost/build/phase13/measure-calibration-01/report.json`.

The first lifting image changes only `norm_eval_node`: seven choices become
fourteen named workers. The original single Unit argument grows to three through
six arguments per selected packet. Removing closures therefore exchanges one
allocation pattern for another; no memory or speed gain follows from the static
site count alone. Its bounded resource gates pass; the controlled timing result below rejects it.

The dynamic operation probe confirms the tradeoff on two-module source graphs
with 4, 16 or 64 definitions per module. At 64 definitions per module, 4,254 selected closures become named-worker
entries, but the total trampoline dispatch count remains 60,344. Argument-array
elements grow from 70,287 to 91,557, an increase of 21,270. A lower `run_tail`
call count here means explicit messages replaced calls; it does not mean fewer
messages. Evidence: `selfhost/build/phase13/rewriter-counts-01/report.json`.

The exact first image passes paired fresh-string and both 53/60-history controls:
226 complete historical observations match both the released results and the
paired baseline. This establishes the bounded resource gate for that image,
not general correctness of the rewrite. Independent synthetic controls found
guard bugs involving shadowed `undefined` and compound shifts. These failures
are preserved and block wider use until corrected.

## Initial performance decision

| Complete-source pilot | Baseline mean | Candidate mean | Process reduction |
| --- | ---: | ---: | ---: |
| Named branch workers | 27.4538 s | 27.7322 s | −1.01% |
| Original-body selector fusion | 27.3299 s | 25.5166 s | 6.63% |

Each row is its own exclusive fresh-process ABBA comparison, not a ratio across
unpaired runs. Both use the unchanged Phase8 worker, identical full compiler
source/host/runtime and independently validated API-specific Base caches.
Two samples per image screen useful effects; they do not establish a statistical
confidence interval or predict other workloads.

Plain lifting is rejected. The [selector followup](selector-fusion.md) removes
intermediate dispatch work and earns a bounded inventory of other owners under
the same rule. Its semantic controls, actual surviving-body byte identities and
paired histories pass. No prototype is installed, and no new TypeScript speed
ratio, conformance improvement or Bend source reduction is claimed.
