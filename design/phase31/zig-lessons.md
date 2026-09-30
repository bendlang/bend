# Phase 31: lessons from Zig's compiler performance history

Research date: 2026-09-30. This is a primary-source research and experiment
design, not evidence that any proposed Bend transformation is correct or fast.
Read alongside the [Phase 30 frontier](../../implementation/phase30/remaining-hypotheses.md).
No Zig toolchain was installed and no Zig benchmarks were run for this review.

## What actually made Zig faster

**2021, Zig 0.8: change representation, then remove repeated work.** Andrew
Kelley's release account describes compact, indexed, struct-of-arrays token/AST
storage, with uncommon payloads in a separate array. Its parser measurement
reported 22% less wall time, 28% fewer instructions and 15% fewer cache misses.
A separate synthetic million-call program improved from 0.93 to 0.57 seconds
after ZIR layout work. These are different experiments, not additive gains.
Whole-file, immutable, untyped ZIR also made frontend caching simpler: unchanged
files could skip tokenization, parsing and AST lowering. The advertised 8.9
million lines/second explicitly excluded semantic analysis and code generation.
The AST/token rewrite took 176 commits and thousands of changed lines; this was
not a free simplification.
[Official 0.8 release notes](https://ziglang.org/download/0.8.0/release-notes.html#Reworked-Memory-Layout).

**2022-10-31, Zig 0.10: self-hosting was a milestone, not the entire speedup.**
The new default compiler, still normally using LLVM, built itself in 40 instead
of 43 seconds and used 2.8 instead of 9.6 GiB peak RSS on the reported i9-9980HK.
The authors expected larger compilation gains from their own code-generation
backends. These measurements do not establish faster generated programs.
[Official 0.10 release notes](https://ziglang.org/download/0.10.0/release-notes.html#Self-Hosted-Compiler).

**2023-08-04, Zig 0.11: canonical identity and incremental infrastructure.**
The release identifies InternPool as a significant step toward incremental
compilation, not a completed incremental compiler or a standalone speed claim.
[Official 0.11 release notes](https://ziglang.org/download/0.11.0/release-notes.html#Incremental-Compilation).

**2025-08-19, Zig 0.15.1: cheaper code generation and parallel pipeline work.**
The self-hosted x86-64 backend became the Debug default except on three named
operating systems. The notes report roughly fivefold shorter compilation than
LLVM in many cases, while explicitly acknowledging slower emitted machine code.
They separately report a self-build improving from 13.8 to 10.0 seconds with
parallel semantic analysis, code generation and linking. Incremental compilation
was still experimental; checking without binary emission was the recommended
reliable use. None of these figures predicts Bend's execution speed.
[Official 0.15.1 release notes](https://ziglang.org/download/0.15.1/release-notes.html#Compiler).

**2026-07-28: incremental work, including the linker.** Core developer Matthew
Lugg demonstrates a roughly five-second initial Fizzy build followed by 50–70 ms
edits on a then-current development compiler. The account separates per-file
ZIR caching, dependency-tracked semantic units, per-function code generation and
binary patching. Dependencies distinguish declaration type, value and other
observations; unchanged results can stop further invalidation. The demonstrated
workflow principally targeted x86-64 Linux and retained known bugs. It is an
edit-latency example, not a cold-build benchmark or stable portability claim.
[Maintainer's dated account](https://mlugg.co.uk/posts/incremental-compilation-internals/).

The three release dates above are also recorded in the
[official download index](https://ziglang.org/download/index.json). This history
does not assert that 0.15.1 is today's latest release.

## Architecture checked against source

The reviewed source is pinned to Zig **0.15.1**, avoiding a changing master:

- [AST](https://github.com/ziglang/zig/blob/0.15.1/lib/std/zig/Ast.zig)
  stores tokens and nodes in `MultiArrayList` containers, uses 32-bit indexes,
  and puts extra data in a separate array.
- [ZIR](https://github.com/ziglang/zig/blob/0.15.1/lib/std/zig/Zir.zig)
  is untyped output of AST lowering. It carries enough information for later
  analysis without routinely rereading the AST; its comments name exceptions.
- [AIR](https://github.com/ziglang/zig/blob/0.15.1/src/Air.zig)
  belongs to individual functions and is consumed by code generation. It has
  separate operations for arithmetic variants rather than silently treating
  wrapping, checked and floating-point arithmetic alike.
- [InternPool](https://github.com/ziglang/zig/blob/0.15.1/src/InternPool.zig)
  provides canonical typed indexes, explicit dependency tables and tracked ZIR
  identities across edits. Its documented index-equality shortcut requires the
  same pool and matching types. A hash by itself is not semantic equality.

The transferable idea is to choose a compact representation for each stage's
actual operations and make reuse boundaries explicit. Copying Zig's entire IR
stack or interner would add substantial machinery without proving benefit.

## Experiments for Bend, in priority order

These are our inferences and prospective decision rules, not Zig results or
promised speedups. Preserve correctness, measurement and promotion separately.

| Priority and hypothesis | Cheapest discriminating experiment | Required evidence before integration |
| --- | --- | --- |
| 1. Private structured computation suffers repeated representation work. | Extend the saved complete-array row across initialization and its private helper graph; compare whole-region calls, record-shell elimination and demand-preserving forcing as separate variants. | Complete arrays, aliases and ordered writes match; operation counts identify what disappears; a frozen confirmation and a second unrelated fixture improve. |
| 2. Repeated analysis is making region recognition expensive. | Count visits, type queries, normalizations and allocations while deriving the existing region plan; try request-local memoization of one demonstrably repeated pure query. | Include setup cost and peak memory; compare checked compiler requests as well as emitted bytes. Cache keys bind the complete relevant book, environment and term identity. |
| 3. A compact private instruction plan can replace repeated tree reconstruction. | Represent one admitted region with indexed instructions and side tables; compare against existing `JSlot`/`JCall`/`JIf` production planning. | Same admission/rejection and output semantics; fewer traversals or allocations; no regression in compiler latency. Expand only if it can retire recognizers or duplicate walkers. |
| 4. Immutable frontend work can be reused across edits. | First measure the fraction already skipped by checked Base caches. Prototype one per-module pre-semantic cache and replay a fixed edit sequence. | Cold/warm/edit timings remain separate. Import changes, changed compiler/Base/options, diagnostics and malformed caches must invalidate correctly. Do not cache semantic verdicts using source bytes alone. |
| 5. Canonical small IDs may reduce repeated names and structural comparison. | Profile one compiler request; only if this work is material, intern names or one immutable analysis structure within that request. | Preserve exact collision checks and original diagnostic spelling; include construction cost and memory. The existing exact-name trie is the baseline, not an assumed missing feature. |

The first experiment directly targets **generated-program speed**. The others
primarily target **compiler throughput and iteration latency**. A compact IR
might enable better generated code, but that is a separate measured outcome.

The current implementation already has
[private region planning](../../selfhost/src/back/js/region.bend) and a
[persistent exact-name index](../../selfhost/src/core/index.bend). Region planning
currently restricts intermediate/helper values to scalars and allows only
terminal record results with computation-free fields. Extending that boundary
needs an explicit locality and demand argument, not merely a broader type test.

The retained [array-row experiment](../../implementation/phase30/closed-owned-native-calls.md)
still performs 258 projections, copies 384 private field slots and invokes
`force` 600 times at its instrumented point. These counts motivate the first
experiment but are not measured time shares. In particular, removing a record
shell must preserve delayed `Array.set` timing, repeated forcing behavior and
shared array handles. Storage specialization remains a separate ablation.

## Keeping the loop fast and the conclusion honest

Use saved generated modules for initial counterexamples and seconds-scale
screens. Change one mechanism at a time. Admit a compiler change only after an
independent semantic review, then use checked B1 and focused emitted fixtures
before expensive transfer gates. Keep both a scalar canary and a generic
record-heavy canary: Phase 30 showed that one can improve while the other
regresses. Report compilation, generated execution, memory and source complexity
separately. Do not multiply gains measured on different workloads or windows.

For a new broad representation pass, a reasonable prospective promotion target
is at least 20% less execution time on two complete affected fixtures, no
unexplained generic/scalar regression, and bounded compiler overhead. The parent
must freeze exact thresholds with each experiment's inputs before measurement;
these are selection criteria, not estimates. If record elimination is null,
retain it and test demand/forcing separately rather than launching a wholesale
rewrite. Zig's useful example is a sequence of measured architectural changes,
with build latency and output quality treated as distinct objectives.
