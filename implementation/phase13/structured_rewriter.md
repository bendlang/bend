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
