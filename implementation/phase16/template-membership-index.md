# Existing template index: correct, no measured gain

The [design](../../design/phase16/template-membership-index.md) replaces the raw
template list in `sp_initial` with the existing immutable cached-book index,
reusing the already computed binder bound. No new line, definition, type or
index implementation is needed. The isolated candidate is
`selfhost/build/phase16/template-index-build-01`; its checked parent and unchanged
equality derivative pass the ordinary 36-case gate with four inherited exact
differences.

The first counter probe failed because version5 fuses the named lookup helpers
into one loop: wrapping an eliminated helper observes zero calls. Preserve
`template-index-baseline-01` and the consumed first tool. The corrected probe
counts actual name comparisons in a copied private fused lookup body, asserting
the exact instrumentation site before use. Baseline02 and candidate01 each pass
27 controls, including empty books, hits, misses and nested terms. A last hit or
miss at 128 templates changes 128 linear comparisons to zero, with one index
entry. Another 24 complete parsed/specialized program comparisons agree exactly
in `template-index-books-01`.

The exclusive same-final-source matrix `template-index-matrix-01` measures
**28.8561→28.8768 seconds**, about 0.07% slower and effectively flat. TypeScript
takes 2.9650 seconds in that matrix. Peak RSS is also essentially unchanged:
1,819,368→1,818,500 KiB. Index construction is included in complete timing.

**Decision: leave unselected.** Better local operation counts are insufficient
evidence of a workflow speedup. The existing optimized linear loop is already
cheap on this workload. No performance claim is attached to the candidate.
