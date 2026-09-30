# Phase31: closed local data and compiler performance

Agent-generated investigation,2026-09-30. **Checked07 is installed and verified**;
all42 ordinary/relocated CLI checks pass. The [release record](release-07.md)
binds final identities, fresh scoped validation and the explicit performance
tradeoffs. No PR comment was posted.

Start with the [implementation report](closed-local-regions.md) and
[measured ablations](local-data-ablation.md). Final07 makes a complete256×256
edit-distance pair29.09× faster and a distinct array fold17.67× faster than17.
The remaining TypeScript ratios are13.66× and16.92× under the same fixed protocol.
The fold still warms. These are generated-program results, not compiler throughput
or a production average.

## Design and mechanism

- [Campaign design](../../design/phase31/local-data-and-compiler-throughput.md)
  and [Zig primary-source study](../../design/phase31/zig-lessons.md).
- [General local-region admission](../../design/phase31/checked-local-regions.md),
  [private demand proof](../../design/phase31/fully-demanded-private-results.md)
  and [direct-field proof](../../design/phase31/direct-private-field-reads.md).
- [Final integration plan](../../design/phase31/final-integration.md) and the
  explicit [performance tradeoff amendment](../../design/phase31/admission-tradeoff.md).
- [Next transformations](../../design/phase31/next-local-transformations.md):
  return-position unpack statements, then proved tuple producer/consumer fusion.
  Neither is implemented or credited with a measured gain.

## Evidence

| Question | Report |
| --- | --- |
| What removes the execution overhead? | [Checked ablations](local-data-ablation.md) |
| Does the gain transfer to original programs, and what does compilation cost? | [Final same-window comparisons](final-measurements.md) |
| Do small probes transfer to a complete computation? | [Full pair](full-pair-transfer.md), [distinct fold](array-fold-control.md) |
| Are demand, aliases and public fallback preserved? | [Independent actual-output review](actual-local-data-review.md) |
| Why did the generic row regress? | [Controlled registration experiment](generic-registration-diagnostic.md) |
| What did the initial disposable prototypes establish? | [Local-data ladder](local-data-ladder.md), [independent review](local-data-independent-review.md) |
| Is the generated compiler spending time in host copying? | [H17 attribution](h-attribution.md), [checker profile](h-checker-profile.md) |
| Which runtime controls cover the bundle? | [Runtime support](local-runtime-support.md) |
| Which final gates pass? | [Final conformance](final-conformance.md), [independent review](independent-release-review.md), [release closure](release-07.md) |

The final long canary has a real4.01% zero-work entry regression (about0.18µs)
and5.04% generic-row regression. Adding one unused valid worker registration
to old output reproduces96.97% of the latter's same-window excess. The original
no-regression criterion is retained as failed; the new selection is an explicit
tradeoff, not a revised interpretation of the old measurements.

The implementation adds236 Bend lines (+1.41%),34 definitions and one module,
with no new datatype declarations. Public representations remain unchanged.

## Reproduction and preserved failures

Frozen inputs and raw receipts live under `selfhost/build/phase31`; the durable
[evidence capsule](evidence/README.md) supplies recovery and dependency details.
Use the maintained [checked workflow](../../docs/PHASE5_DEVELOPMENT.md), not a
handwritten diagnostic module, to acquire an actual compiler/output pair.

Build attempts01–03 are not usable: review fixed an Array-free Sigma guard
omission, then execution exposed the missing regenerated runtime bundle.
Checked04 fixed packaging. The36 focused frontend checks alone had not detected
that fault. The07 owner state observer was amended explicitly after generic
project calls disappeared; independent physical-handle observations already
worked. All failed runs and consumed tools remain evidence.

The [start inventory](start-state.json) protects103 unrelated files.
[Verified disk recovery](verified-space-recovery.json) reclaimed only redundant
Phase30 synthetic books whose original archive bytes were independently verified.
The [prior consolidated release](../phase30/release-17.md) and its historical
measurements remain unchanged.
