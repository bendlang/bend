# Rejected: preflight before the private-vector inliner

Root rejected and reverted the 11-line preflight after its isolated checked
comparison. It removes real unnecessary traversal, but only saves 1–2% on the
three scalar workloads while pair's median rises 4.48% with overlapping ranges.
The additional pass/helper is not justified by this result. No compiler-cost win
from this experiment belongs in the final compiler's claimed gains.

The hypothesis, source patch and controls remain in
[P36-003](../../experiments/phase36/P36-003-analysis-preflight.md). The
[extracted data](cost-data.json) preserves all request samples, ranges and full
boundary statistics, exact module identities and raw receipt hashes. The
[read-only extractor](cost-extract.py) verifies those artifacts without running
the compiler.

## Correctness and mechanism

The cost-only checked01 API is
`0e47b65bfd5483aa2fc354bd0bdfd5b37f6e9e7df937105cb1c703c7c5e32d1e`.
Its checked B1 build plus Focus36 passed in **42.892 seconds**, supervised peak
RSS **1,128,304,640 bytes**. This is not a new self-emitted fixed point.

All ten synthetic controls passed. A scalar `Ann` helper drops from three
diagnostic inline visits to zero; the native-only case drops four to zero. The
positive vector-call case retains all twelve visits and the same emitted bytes.
Source metadata, residual/native/non-Def exclusions and exhausted-budget fallback
remain equivalent in their named controls. These are internal mechanism counts,
not CPU samples or performance measurements.

Fresh preparation confirms identical emitted bytes for **all 15 catalog points**
(13 unique source compilations, including their adapter outputs) against
Phase35 checked09. The normal checked timing worker separately verified every
expected module byte for byte. Source/runtime behavior therefore remains
unchanged for this observed catalog, and no generated execution speedup is
expected from this cost-only patch.

## Normal checked compilation

All **36/36 requests passed**, taking **272.232 seconds** in the supervised
comparison. Each cell below is median milliseconds and the observed min–max
over three rotated fresh-process samples, not a confidence interval.

| Source | Phase35 baseline | Preflight candidate | TypeScript | Candidate median change |
| --- | ---: | ---: | ---: | ---: |
| Local pair | 1,911.387 (1,885.377–1,926.772) | 1,997.021 (1,897.809–2,071.045) | 327.167 (326.135–327.464) | +4.48%; overlap |
| Mandelbrot | 2,116.783 (2,102.223–2,127.178) | 2,079.398 (2,078.232–2,080.211) | 367.781 (355.901–373.853) | −1.77%; disjoint |
| Symreg | 2,233.847 (2,210.859–2,241.729) | 2,192.280 (2,188.735–2,207.108) | 320.516 (312.186–347.597) | −1.86%; disjoint |
| Ray tracing | 2,922.967 (2,906.972–3,177.561) | 2,890.064 (2,874.929–2,891.461) | 443.666 (443.636–474.428) | −1.13%; disjoint |

The ray baseline has a high first sample; all three candidate samples are below
the baseline minimum, but three rotations cannot establish a precise population
effect. Pair's overlap prevents a confident claim of regression, yet also gives
no basis to dismiss its adverse median. Absolute times differ from Phase35's
earlier acquisition; the valid comparison here is the same-run rotated pair.

The unchanged normal worker performs ordinary checked-library requests including
lazy API loading and a validated Base cache. Compiler setup/import, supervised
process verification and request time remain separately reported. The worker
hash stays `f0dea569bdb02df60ed1156b0cead389e197291f1c3a3c6775102c7a03790f42`.
Node, CPU3, a one-GiB Node heap, a two-GiB process-tree ceiling and host-memory
floor, and serial shared-lock execution remain bound by the saved plan.

## Decision

The expected identity-pass mechanism is real, but it is not the main explanation
for Phase35's 8–34% cost growth. Adding a scan that benefits scalar closures and
adds work before vector closures is a poor trade at these observed magnitudes.
Retain the original source and the negative evidence. A later cost experiment
needs stronger attribution, such as counts/profiles of repeated purity/type
proofs, before introducing a cache or further analysis machinery.

Raw artifacts remain under `selfhost/build/phase36/checked01`, `cost-controls01`,
`cost-full01`, `cost-plan01` and `cost-run01`. The final Phase36 preservation step
must retain them with the other rejected attempts. This report does not itself
claim those raw artifacts have already been archived durably.
