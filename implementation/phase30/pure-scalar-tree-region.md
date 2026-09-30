# Scalar binary-tree region experiment

The generated-JavaScript experiment passes its semantic and mechanism gates.
It removes almost all remaining generic application work from the original
Mandelbrot second pass. The clean long confirmation shows a 15.6× gain on the
original small program over checked attempt10, with an important remaining
warmup effect in the candidate. No compiler implementation has yet been made
for this experiment.

The prospective design is
[pure-scalar-tree-region.md](../../design/phase30/pure-scalar-tree-region.md).
The unchanged control is the checked whole-program attempt10 emission, SHA-256
`7adaa8e0c2d4e9de4e607d49027956456db631da1bcc60faa1be38f5a79aa140`.
That compiler already includes lexical scalar helpers and the terminal-record
first-pass region. The comparison therefore measures a remaining second-pass
opportunity, rather than reusing an older unoptimized first-pass baseline.

## What the experiment changes

The `rcol` successor body computes two predecessor-recursive scalar results and
combines them. The prototype lowers this exact shape to a private iterative
depth-first evaluator. A frame holds original immutable scalar arguments, a
phase and the completed left result. The right arguments are evaluated after
the left child, using the saved parent predecessor for the original dynamic
Nat shift. The combination keeps its original primitive expression. No host
recursion, tree flattening or arithmetic reassociation is introduced.

Three variants isolate the boundaries:

| Variant | Tree traversal | Leaf work |
| --- | --- | --- |
| `baseline` | Original generic applications | Original public calls |
| `public_leaf` | Private explicit stack | Original public `rpix` call, forced at its original demand point |
| `private_leaf` | Same private stack | Private complete scalar closure, including the existing BigInt `mit` loop |

Both private traversals require exact application permission, original slots
read once, native scalar inputs, projected predecessor `0 <= p < 32n`, and a
live guard for all nine owner/helper descriptors. Public Zero entry remains
unchanged. Raw calls, oversaturation, hooks, malformed inputs, changed bindings
or a failed guard execute the original generic callback. The depth cap is an
admission limit with a generic fallback, not a new language restriction.

The prototype is a diagnostic source-to-generated-output transformation. A
production implementation would still need a checked-book proof for the exact
binary recursion shape, shared helper-analysis budgets, refusal cases and
compiler regression gates. Current established original-program coverage is
one owner (`rcol`) and its eight scalar dependencies.

## Validation

The derivative was acquired from the checked attempt10 module after the design
was frozen. Independent static review approved the entry scheduling, saved
parent aliases, closed public-leaf ablation and explicit-stack shape before
execution. The following acquisition-only gates passed on CPU5:

- **74 independent oracle points:** 72 small-tree combinations of depth,
  starting index, inner iteration count and extreme U32 palette, plus both
  original `bench(0,0)` and `bench(2,0)` results, across all three variants.
- **130 paired host observations:** closure replacement and descriptor
  mutation, saved partials, raw and forged calls, constructor calls, slot and
  environment reentry, throwing or coercible inputs, oversaturated copied
  vectors and subsequent-call visibility.
- **8 separate depth-admission sentinels:** public depths 1 and 32 select the
  private body; depth 33 and a raw coercible predecessor select the generic
  body, with an otherwise pristine closure. The sentinel copies are excluded
  from timing and avoid evaluating an exponentially large tree.
- **30 stack/mechanism checks:** small-tree leaf order including U32 wrapping,
  `2^d` leaves, `2^d-1` combines and frames, and stack high-water exactly `d`.
  The private evaluator contains no recursive host tree call.

Raw controls retain complete observations. Their report is approximately 1.6 MB;
the summary counts above refer to cases, not individual trace events.

## Mechanism evidence

Separately instrumented copies produced these counts for original
`bench(2,0)`, with the complete result `887240761` in every variant:

| Operation | Baseline | Public leaf | Private leaf |
| --- | ---: | ---: | ---: |
| Generic apply | 12,112 | 6,248 | 104 |
| Function descriptor | 7,742 | 2,388 | 84 |
| Partial application | 6,440 | 1,596 | 60 |
| Jump | 1,815 | 1,561 | 25 |
| Force | 10,297 | 4,943 | 79 |
| Projection | 782 | 528 | 16 |
| Closure guard evaluations | 260 | 261 | 5 |
| Build / constructor | 8 / 8 | 8 / 8 | 8 / 8 |

The private traversal visits 511 nodes and 256 leaves, performs 255 combines,
and reaches a stack high-water of 8. Its complete leaf-index trace is 0 through
255 in source order. The private-leaf variant retains four first-pass chunk
guards and adds one second-pass tree guard; the public-leaf ablation still has
256 inner `mit` guards. These counts establish the intended removed work.
They do not establish wall-clock speed or justify multiplying earlier gains.

## Reproduction and pending measurement

Maintained tools are under `selfhost/tools/performance/phase30/`:
`prototype-tree-region-derive.py`, `prototype-tree-region-controls.mjs`,
`prototype-tree-region-counts.mjs` and `prototype-tree-region-plan.py`.

Immutable raw evidence under `selfhost/build/phase30/`:

- `prototype-tree-01/derive.json`: checked source, copied source receipt,
  parser proof, exact transformed modules and hashes.
- `prototype-tree-controls-01/report.json`: complete oracle and ordered host
  observations, plus distinct diagnostic depth-sentinel modules.
- `prototype-tree-counts-01/report.json`: six whole-program counter rows and
  thirty independent explicit-stack checks.
- Corresponding `prototype-tree-{derive,controls,counts,plan}-01-outer/`
  receipts: complete launcher output, tools, duration and exit status.
- `prototype-tree-plan-01/{screen,confirm}.json`: frozen original-small and
  depth-five tree timing points; original-small additionally includes pinned
  upstream TypeScript. Instrumented and sentinel modules are excluded.

The clean short screen (`tree-screen-01`, outer duration 14.093 seconds) passed
every output. Whole-original median milliseconds were 6.10423 for baseline,
4.54001 for public leaf, 0.380906 for private leaf and 0.0477858 for TypeScript.
The private sample range was 0.379251–0.388151 ms. Baseline and public-leaf
halves were still warming by roughly 10–32%, so their short-window ratio is not
the final estimate. Private-leaf halves ranged from −1.48% to +3.67%.

At depth five, baseline/public/private medians were
0.667310/0.471631/0.0292556 ms. The private half-window changes stayed within
0.82%. This justified executing the already frozen long confirmation; no
configuration or artifact was retuned after the screen.

The clean long confirmation (`tree-confirm-01`, outer duration 147.502 seconds)
passed every output. Medians and complete independent-process sample ranges:

| Case / variant | Median ms | Range ms |
| --- | ---: | ---: |
| Original small / baseline | 5.017372 | 4.925327–5.271815 |
| Original small / public leaf | 3.253234 | 3.236538–3.287595 |
| Original small / private leaf | 0.321506 | 0.319410–0.322686 |
| Original small / TypeScript | 0.045557 | 0.045361–0.045756 |
| Depth five / baseline | 0.546154 | 0.540401–0.555638 |
| Depth five / public leaf | 0.371228 | 0.367526–0.393665 |
| Depth five / private leaf | 0.025167 | 0.025033–0.025958 |

The private whole-program protocol throughput is **15.606× faster** than
attempt10 and **7.06× slower** than pinned TypeScript at this exact point.
Private whole-program halves consistently improve by 25.4–27.8% within each
sample. Their tight average range therefore does **not** establish settled
steady-state throughput. The observed large gain is supported by disjoint
ranges and mechanism counts; the precise warm rate needs a separately frozen
longer-warmup experiment if required. Baseline whole-program halves are mostly
within 1.1%, with one −5.82%; public-leaf halves stay within 2.77%.

The independent depth-five point improves **21.701×**, with private half-window
changes mostly within 1.24% and one +3.03%. It provides a more stable small
iteration point for the same private tree/leaf mechanism. This is one original
program and one derived component, not a general generated-program speed claim.

Independent review subsequently requested additional primitive-marker,
descriptor-metadata and copied-length boundary cases before promotion. They
are frozen separately in
[pure-scalar-tree-additional-controls.md](../../design/phase30/pure-scalar-tree-additional-controls.md).
The existing modules, controls and timing inputs remain immutable. Ordinary
Array intrinsics remain an explicit scope for private continuation storage.

A production proposal depends on confirmed speed and these additional gates,
with a gain large enough to justify the extra binary-continuation analysis and
its refusal proof.
