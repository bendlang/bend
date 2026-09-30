# Sample the corrected scalar fixture after warmup

Prospective diagnostic, separate from clean timing. Profile exact attempt07
fixture bytes with Node's inspector CPU profiler at a 100 microsecond interval.
Warm at least 5,000 calls and 1,000 ms, then sample 30,000 checked calls to
bench(128,524800), expected128. Preserve module/tool/Node identities, the full
profile, warmup count and observed output. Run on CPU7 while other acquisitions
use CPU4/5/6; do not call its duration comparative performance.

Map samples to exact emitted source line/column and runtime function names.
The question is whether scalarGuard, generic entry machinery or the private
loop/helpers dominate sampled execution after the compiler changes. This is
supporting evidence for the independent guard-bypass, lexical-helper and cold
fallback ablations; sampled percentages are neither an exact cost decomposition
nor a representative workload average. Do not modify program bytes to attach
names, and do not mix this profile with clean timing samples.
