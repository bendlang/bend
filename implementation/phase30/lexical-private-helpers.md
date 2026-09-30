# Private dictionary versus lexical helper bindings

The spelling-only generated-output ablation passes its focused semantic checks
and improves the selected helper workload by 3.76× in the independent long-warm
confirmation. No compiler or runtime source was changed by this experiment.

The frozen plan is
[lexical-private-helpers.md](../../design/phase30/lexical-private-helpers.md).
The derivation consumes actual checked attempt07 output, replaces its four
private helper dictionary assignments with lexical function declarations, and
rewrites nine private references inside the same mit IIFE. Public descriptors,
snapshot guards, scalar checks, entry permission, primitives, loop and generic
fallback retain their original bytes outside those private references.

| Output | Bytes | SHA-256 |
| --- | ---: | --- |
| Unchanged attempt07 fixture | 76,612 | 8e9317debb126b7296b67795e3bca8aba871895b1b8ed15e93458f3c03e271a8 |
| Lexical private helpers | 76,608 | 8347d2a6095dc3ef3ae4503760acb483adb8a396491ee03bdfb0393c7f5d33e7 |

Fresh CPU6 acquisitions retain the consumed tools, source identities, exact
derivation and results under `selfhost/build/phase30/`:

- `review-lexical-01`: both modules, changed-site evidence and prospective
  paired screen/confirmation configurations.
- `review-lexical-ordinary-01`: 130 ordinary ABI/getter/effect/error comparisons
  and 72 independent arithmetic/long-loop observations pass.
- `review-lexical-entry-01`: nine exact-entry, reentrancy, hook and exception
  cleanup comparisons pass.
- `review-lexical-full-01`: after review identified that both sides have the
  same runtime, all 146 ABI/effect/prototype observations and 72 scalar runs
  pass. This includes the sixteen prototype observations unnecessarily skipped
  by the initial preworker-derived configuration. The original receipt remains.

Both sides use the same current runtime. The inherited standard-prototype
effect-trace limit against older compilers remains documented in the attempt07
checkpoint; this derivative adds no differences on the sixteen measured cases.
No additional scope weakening is needed for this ablation. These tests establish
the selected observations, not all backend conformance.

The lead's measurement agent ran the frozen paired protocols with exclusive CPU3
and no overlapping acquisitions. The unchanged 128-iteration point is
`bench(128,524800)`, expected result 128. The screen and long-warm confirmation
are separate process populations and both remain in the evidence.

| Window | Unchanged median | Lexical median | Ratio |
| --- | ---: | ---: | ---: |
| Three-process screen | 0.043533 ms | 0.013581 ms | 3.21× |
| Five-process long-warm confirmation | 0.037566 ms | 0.009998 ms | 3.76× |

The screen has substantial opposite timed-half drift: the baseline improves
about 18–19% while the lexical variant worsens about 48–50%. It alone was
insufficient for promotion. The confirmation uses the predefined three-second
warmup. Its baseline range is 0.037252–0.038179 ms and lexical range is
0.009966–0.011565 ms, with no overlap. Baseline half drift stays within 0.54%;
four lexical samples stay within 2.64% and one improves 9.71%. That remaining
variation stays visible. First-call medians are about 2.291 ms and 2.264 ms,
respectively; the large improvement concerns warmed execution, not startup.

Raw results are `lexical-screen-01/report.json` and
`lexical-confirm-01/report.json` under the same Phase30 build directory, with
launcher receipts, process samples and output identities. The long confirmation
records 42.05 seconds inside the maintained harness. No sample was discarded.

This intervention retains all exact-entry and descriptor guards. It therefore
shows that the helper-binding representation accounts for a large removable
cost at this point, without establishing how the host optimizer distributes
that cost among property loads, calls or inlining. Samples attributed to the
shared enterExact call site cannot be interpreted as token-check cost. Transfer
to actual compiler output and original programs remains the next required gate;
this is not a whole-compiler throughput or production-average claim.
