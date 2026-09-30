# Checked local representation changes

The selected local candidate is checked03, built from the Bend source with the
maintained equality profile. It is not a newly self-emitted H compiler. Broad
integration and installation are recorded separately in the phase index.

The same-source ablation retains checked01 (statements), checked02 (typed read
fusion), checked03 (private vectors), Phase31 checked07 and pinned TypeScript.
Every row below comes from the same long confirmation window: five rotating
fresh processes per variant, at least100 calls **and** three seconds of warmup,
then a300ms timing target. Every result is checked. The entire confirmation took
211.62 seconds and peak supervised process-tree RSS was146 MiB.

| Generated variant | Full pair, ms | Independent fold, ms |
| --- | ---: | ---: |
| Phase31 checked07 | 18.5348 | 0.65053 |
| Statement unpacking01 | 8.8798 | 0.52758 |
| Typed read fusion02 | 6.5404 | 0.40762 |
| Private vectors03 | 4.9254 | 0.32914 |
| Pinned TypeScript | 1.3021 | 0.040465 |

The combined candidate is3.76× faster on the complete pair and1.98× on the fold.
Its remaining same-window TypeScript gaps are3.78× and8.13×. Every successive
candidate's observed timing range is disjoint from its predecessor on both
fixtures. These are selected generated-program execution measurements, not
compiler throughput or a production average. First calls, imports, process
memory, exact inputs, half-sample drift and all observations are retained in
`selfhost/build/phase32/local-checked-confirm-03/` and the final evidence capsule.

The short screen took19.65 seconds and suggested larger fold gains. Its fold
numbers must not replace the longer-warm measurements above. The long test is
confirmation of a specific frozen candidate, not an invitation to select the
best window or omit warming behavior.

## What changed

Return-position pattern unpacking emits scoped statements rather than invoking
an anonymous function solely to bind fields. Capturing the input outside the
binding scope preserves shadowing; all reads still precede the arm.

An immediate canonical array read into a proved private pair consumer becomes a
typed bridge. It evaluates the prior arguments and read arguments in their
original order, captures the handle and indexed value, and runs the consumer.
This removes the temporary pair. It does not defer or eliminate an unused read.
Other tuple producers and public helpers keep their existing behavior.

Private constructors emit ordered field vectors where the existing closed
region proof permits them. Ordinary nonterminal records lose their outer tagged
shell; canonical Sigma construction also avoids runtime constructor dispatch.
The [precise ablation scope](../../design/phase32/vector-ablation-scope.md) matters:
fold has no ordinary record-shell change, so its final increment is not evidence
for record-shell removal alone. Public terminal scalar records, including their
aliases and nested occurrences, remain boxed.

All changes reuse existing local-type, native provenance, public-entry and
closed-call proofs. The runtime is unchanged. The independent review and
[focused gate summary](review-local-gates.json) record full array contents,
logical allocation/read/write events, scalar oracles, evaluation order,
throwing/mutated public descriptors, alias normalization and public record shape.
Full pair preserves all328,966 native events. Each gate ran separately under a
memory cap; the largest used293 MiB.

## Cost and limits

The compiler adds57 physical Bend lines (+0.335%) and six functions, with no
new datatype, law or module. Two private plan tags and three local mechanisms
are added; this is a measured small complexity increase, not a line-count
reduction. The pair module grows4.21% and fold1.08%, mostly from read bridges.
Some eligible bridges can be emitted without a matching producer. See
[source and generated-size accounting](local-complexity.md).

The [original-program transfer and compilation measurements](README.md) decide
release admission alongside conformance. These local results do not establish
a universal improvement, GPU conformance or a new bootstrap fixed point.
