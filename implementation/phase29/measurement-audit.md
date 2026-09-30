# Phase 29 independent measurement audit

This review audits recorded measurements independently of the compiler changes.
The final semantic decision is in [semantic-review.md](semantic-review.md).
**The final measurement audit passes.** All nine library campaigns and the
separate application comparison are closed, including the prospectively added
evening confirmation. The machine-readable decision is
[measurement-audit.json](measurement-audit.json). This verifies the recorded
comparisons and their qualifications; it does not turn every observed gain into
a universal performance claim.

## Identity and scope

The final checked compiler API is
`10510efda268bac1f31cc8fed87a9315e8f9edfa15aad6b90b0d96756c217b11`.
The previous release API is
`5a89c775e903374341da4b4e32c29d26ffe687677f088c590046f748b69d81c5`;
the unchanged runtime is
`40823818afd57a6c37e055272dc332f461955a7cd225f67d66194f0d43ec823f`.
The TypeScript reference is pinned upstream
`018751270e800bc222a93dad7f257083ee53a5f7`.
Arithmetic-only output and disposable handwritten JavaScript interventions have
their own recorded identities. They are separate evidence, not interchangeable
with output from the final checked compiler.

The comparisons measure generated JavaScript execution. They do not measure the
self-hosted compiler's throughput or a new self-hosted fixed point. Every library
case compares identical source, arguments and complete expected output, with the
original full-program inputs retained. The application case includes process
startup and exit and therefore has a separate measurement scope.

## Independent checks

[`controls-audit.py`](../../selfhost/tools/performance/phase29/controls-audit.py)
executes no generated programs. It rehashes declared inputs, output modules,
configuration and runner files; checks raw stdout against each launch record and
the aggregate report; checks successful completion of correctness, calibration
and timing children; verifies full first-call output and accumulated checksums;
and recomputes sample medians, ranges and first-call medians. The inspected runner
asserts the complete result on every invocation, including warmup and timed calls.

The audit checks Node 24.18.0, CPU 3 affinity, 4096 KiB stack, 1024 MiB heap,
timeouts, both warmup floors, calibration doubling and its stopping rule, fixed
repetition counts, rotating variant order, and serialized child intervals. It
requires every configured case and sample to survive into the final report. The
root agent paused other builds and generated-program runs during these windows;
the raw records establish serialization of recorded children, not absence of all
unrelated host activity.

[`controls-application-audit.py`](../../selfhost/tools/performance/phase29/controls-application-audit.py)
separately checks all fifteen whole-process HVM samples, byte-exact stdout, empty
stderr, exit status, ordering, timing intervals, hashes and medians. It also
replays the exact recorded derivation of the prior application runner. An inherited
runner exit code alone is insufficient: the audit requires `allSamplesValid` and
each individual successful sample.

## Windows retained

The nine library campaigns contain **586 subprocesses and 414 timed samples**;
the separate HVM comparison contains **15 complete-process samples**. The total
recorded inventory is **601 subprocesses / 429 timed observations**, with the
two measurement scopes kept separate. The library audit performs 17,947 assertions
over 239 distinct hashed files; the application audit performs 207 assertions over
57 files. Those file sets overlap, and these are not conformance-test counts.

The final raw receipts are
`selfhost/build/phase29/controls-measurement-audit-final-04.json` and
`selfhost/build/phase29/controls-application-audit-final-04.json`.
[`controls-audit-close.py`](../../selfhost/tools/performance/phase29/controls-audit-close.py)
combines them with 623 further checks, including all 601 child intervals across
the library/application boundary, the full campaign inventory, unchanged evening
input/module identities, and execution of its follow-up after all planned jobs.

| Campaign | Subprocesses | Timed samples | Internal campaign seconds |
| --- | ---: | ---: | ---: |
| Prototype short screen | 30 | 18 | 10.722 |
| Prototype longer-warm confirmation | 42 | 30 | 125.909 |
| Arithmetic-only selected transfer | 63 | 45 | 91.003 |
| Final paired fixture screen | 10 | 6 | 3.908 |
| Final fixture confirmation | 28 | 20 | 83.622 |
| Final original-program transfer | 231 | 165 | 1321.582 |
| Final selected-program confirmation | 98 | 70 | 317.312 |
| Final component confirmation | 63 | 45 | 188.789 |
| Evening longer-warm follow-up | 21 | 15 | 63.883 |

The fifteen HVM process samples are additional to this library table. Their
launcher takes 3.744 seconds end to end; those process-lifecycle samples are not
calibrated library calls.

The internal campaign timer excludes initial Python startup and input hashing.
The final paired screen takes **4.706 seconds end to end**, compared with its
3.908-second internal timer. The full original-program transfer takes **1322.9
seconds end to end**. The fast screen and expensive integration boundary serve
different purposes; the latter is not required for every local mechanism trial.

## What the current numbers establish

The final fixture improves from 2.766114 to 0.415392 ms/call in the short window
(6.66×), but its old output slows by 2.26–2.31× between timed halves. The
longer-warm comparison gives 1.455003 to 0.398719 ms/call (3.65×). All halves in
that fixture confirmation differ by less than 10%. This finite check supports
reporting the longer-window gain separately; it does not prove convergence or
universal steady-state performance. TypeScript output still takes 0.001703 ms,
about 234× less time on this fixture input.

All six original algorithm cases improve in the original transfer window,
from 1.238× on edit distance to 2.939× on Mandelbrot. Their remaining ratios to
TypeScript output range from about 89× to 465×. These are per-case observations,
not an average generated-program performance claim. Arithmetic-only and combined
lexer/sorting outputs are byte-identical: variation between their timings cannot
be attributed to the new worker mechanism.

The original transfer flags over 10% half-to-half drift on exactly Mandelbrot,
tree sorting, morning, map/set and evening. The first four already have frozen
longer-warm confirmations. Lexer, symbolic regression and RLE have no such flag.
Edit distance and ray tracing have one timed call in the expensive variants, so
they have no second-half estimate; absence of a drift flag there is not evidence
of stable halves.

**Evening regresses by 27.4% in the original window**, from 0.274290 to 0.349464 ms.
Its old halves differ by 2.17–2.31× and candidate halves by 2.18–4.10×. The added
[prospective follow-up](../../design/phase29/evening-warmup-followup.md) uses the
same source, module and input bytes with the longer-warm protocol. It records old
0.162918 ms versus candidate 0.139563 ms, a **1.167× improvement**, with ranges
0.156580–0.165210 and 0.138695–0.140301 ms. None of its timed halves differs by
over 10%. The follow-up takes 65.071 seconds end to end. Both lifecycle windows
remain reported: this later gain does not erase the earlier regression. Warmup
sensitivity is observed; a specific JIT or allocation cause has not been established.

The original-program confirmations give gains of 2.695× on Mandelbrot, 1.063×
on sorting, 1.090× on morning and 1.065× on map/set. Sorting and map/set still
show material half drift in the longer window. All five sorting candidate
second halves take 1.230–1.295× the per-call time of their first halves; all five
old map/set second halves take 0.830–0.865×. Two map/set candidate halves also
exceed 10% drift. These finite-window gains remain useful but unresolved in their
warmup sensitivity. No additional repeats were selected to improve the headline.

Component medians improve by 1.039× for compiler membership, 1.289× for term
substitution and 1.670× for the Boolean fixture. Their old/candidate sample
ranges do not overlap. Three TypeScript term-substitution samples and one
candidate Boolean sample retain over 10% half drift. The Boolean case keeps its
generic worker path; its improvement does not establish a new worker selection.

The HVM whole-process comparison is flat within the observed overlapping ranges:
old median 196.860 ms (193.566–203.611), candidate 198.393 ms
(195.419–200.655), TypeScript 68.539 ms (65.834–69.961). The candidate median is
0.78% higher than the old median and 2.895× TypeScript. These fifteen complete
processes support **no HVM speedup claim**. They include startup, imports and
execution; the library results separately record imports and first calls outside
the warmed timed blocks. None of these scopes can substitute for another.

## Failures remain part of the record

Attempt 02 failed source admission. Attempt 03 passed focused controls but
overflowed while compiling the original symbolic-regression and ray-tracing
programs. The retained small frontier case independently reproduces that overflow
on 03. Attempt 04 repairs eager recursive recognizer guards; all ten original
programs freshly compile and return exact expected results. Previously successful
03 output remains byte-identical on the eight original programs and the optimized
fixture checked in both attempts. These correctness failures are separate from
the timing sample inventory, and neither failed candidate is promoted.

The combined audit initially compared entire evening point objects and rejected
their intentional warmup/calibration differences. Its initial failed receipt and
source are retained as `controls-audit-close-initial.{json,py}` in the raw tree.
The corrected comparison checks export, arguments, expected result and module
hashes while allowing the prospectively specified protocol change. This was an
audit-tool assertion error, not a discarded benchmark sample.

No measurement-integrity blocker remains for the final candidate. Retain the
short-window evening regression, unresolved sorting/map-set warmup sensitivity,
the remaining TypeScript gaps, and the absence of an HVM speedup when presenting
the result. The separate semantic review supplies the correctness gate.
