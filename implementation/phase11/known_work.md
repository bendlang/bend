# Phase11: using known information to avoid compiler work

Work in progress. The [prospective design](../../design/phase11/known_work.md)
sets the baseline, hypotheses and release gates. Phase10 `5f561c4` remains the
installed compiler; no new gain or semantic change is claimed.

## Evidence and decisions

The final-release profile and three independent upstream/Bend comparisons will
be recorded here, with linked failures, candidate gates and controlled results.

## Fresh final-release profile

Installed Phase10 release verification passes before profiling. The unchanged
Phase9 diagnostic runner checks immutable Phase10 `integrated-01` on CPU0 with
10ms samples, Node24.18.0,4MiB stack and4GiB heap. The ordinary type/expected
unsafe-proof-trust gate and all input identities pass. Its instrumented56.09s
process time is excluded from speed ratios. Raw evidence is in
`selfhost/build/phase11/current-profile-01`; historical tool schema names remain.

Exclusive lexical-owner grouping retains runtime/GC separately; it is not logical
inclusive caller attribution and does not measure allocation counts.

| Lexical owner | Exclusive sampled time |
| --- | ---: |
| `(garbage collector)` | 12.51% |
| `run_loop` | 9.83% |
| `$norm_eval_node$` | 5.64% |
| `$lookup$` | 4.46% |
| `run_tail` | 4.41% |
| `$f_find$` | 3.89% |
| `$norm_match$` | 3.29% |
| `$core_subst_stable$` | 2.94% |
| `$index_find$` | 2.80% |
| `$subst$` | 2.80% |
| `$check_node$` | 2.60% |
| `$index_remove$` | 2.04% |
| `$check_ctr_found$` | 1.85% |
| `$norm_max_term$` | 1.62% |
| `$terms_at$` | 1.46% |

The 5196 samples reconcile exactly with the streaming summary. Raw profile SHA-256:
`36a861431f01365cced5498811e39d232f5e44d2ca3169ba206023559ab87069`. Index lookup is now a smaller share; the current
normalization and branch/dispatch costs justify fresh investigations without
assigning old whole-workflow gains to these sample percentages.
