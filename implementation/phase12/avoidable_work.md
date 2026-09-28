# Phase12: avoid constructing work that will be discarded

Work in progress. The [prospective design](../../design/phase12/avoidable_work.md)
starts from released Phase11 `f8244c9`, preserves unchanged upstream b2111cf and
separates profiling, isolated hypotheses, correctness, measurement and promotion.
The installed compiler remains Phase11 until final gates justify a replacement.

The current planning estimate is not a measured improvement. This report will
record actual outcomes, including rejected and inconclusive attempts, before
publishing any new speed or conformance claim.

## Fresh Phase11 profile

Installed-release verification passes before investigation. The unchanged Phase9
profile runner checks immutable Phase11 `integrated-01` on CPU0, Node24.18.0,
4MiB stack and4GiB heap, at10000us samples. Other investigators remained on
static reading/preparation. Ordinary source/type/expected-trust and all recorded
input identities pass. The instrumented32.467s process is not a timing sample for
a speed ratio. Historical schema names in reused tools are unchanged.

The2,929 raw samples reconcile with the lexical-owner summary. Full data is in
`selfhost/build/phase12/current-profile-01`; raw profile SHA-256 is
`f61c41949cb2b86b07aff19c27ad091242dda877a28b1326c563c822b2e91ba1`.
These are exclusive lexical owners, not inclusive logical caller attribution.
Runtime and GC cost are not assigned to a guessed compiler operation.

| Owner | Exclusive sampled time |
| --- | ---: |
| `run_loop` | 14.26% |
| Garbage collector | 13.75% |
| `norm_eval_node` | 5.20% |
| `lookup` | 4.59% |
| `index_find` | 3.31% |
| `f_find` | 2.92% |
| `norm_match` | 2.70% |
| `check_node` | 2.67% |
| `subst` | 2.46% |
| `update` | 2.24% |
| `index_remove` | 1.87% |

This supports bounded investigation of residual dispatch/allocation but does not
show how much any individual proposal will save. A new full-source counter or
benchmark must establish its own overhead and observation scope. Initial owners
found eager reference fallback reconstruction,229 remaining native-choice sites,
and duplicate JS literal recognition. Large compact-string representation work
is deferred pending evidence that justifies its wider semantic obligations.
