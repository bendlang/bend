# P7-A01 implementation and measurement review

This is the **implementer's own review**, not an independent source review.
Root owns the separate compiler build, execution and cross-proposal assessment.
No production source or installed artifact was changed by this experiment.

## Source boundary

The patch changes successful term construction and wraps successful terms in the
existing backend annotation representation. It preserves `KChecked.typ`, uses
and error fields. The failure branch of `co_typed` returns its input unchanged.
Application checking still checks its function before the existing argument
call; constructor checking still uses the original telescope checker. Lambda
checking retains domain/body checking and the original quantity-use rejection.
The five new helpers are ordinary Bend functions, not host compiler logic.

This does not establish a complete output contract. Let bindings, matcher arms,
rewrite terms and template-instance books are not reconstructed by this slice.
The runtime and backend code are unchanged. All old annotation and specialization
code remains present. Five helpers and 23 lines were added, with zero retired
production lines. There is no source simplification result yet.

## Control evidence

The checked API came from the maintained checked B1 workflow, not a generated-JS
mutation. The controls append exports of existing checked bodies. Nine actual
program pairs execute with exact code and output identity. Seven negative groups
preserve chronology/error observations, including six complete failed result
comparisons. One chronological forward-reference failure appropriately succeeds
when checking the isolated definition against the final book; this distinction
is preserved in the report rather than normalized away.

Input immutability is checked after the positive cross-version comparisons.
The separate timing workers also check their own independently parsed fixture
after running their assigned compiler variant. The broad conformance vector was
not rerun. The 21 maintained focused cases and these narrow controls do not prove
whole-language equivalence.

## Measurement review

The timing driver performs a semantic preflight before any timed worker. It
compares exact checked observations, exact annotated term output and exact
JavaScript bytes, then executes both generated programs. Every measured batch
checks its result hash outside the timed region. Workers load only their assigned
compiler image. They share the same frozen input data and already-built context,
Node version, stack/heap limits and CPU affinity.

Both lanes use fresh A/B/B/A workers. Each worker has three warmup batches and
seven measured batches of 32 calls. The measured operation is one definition
with 128 nested identity calls. The baseline compile-preparation lane explicitly
calls checker and annotator; the candidate calls the checker and takes its output.
Neither lane times parsing, loading, chronology for the whole book or emission.
This is an end-to-end comparison of those small entry calls, not a count of pure
kernel instructions. No full-source or TypeScript ratio can be inferred.

The check-only time regression is approximately 25.4%, with 44.7–46.4% higher
worker peak RSS. The compile-preparation improvement is 16.85–17.67%, with peak
RSS between −0.48% and +1.28%. All samples are retained. The candidate's later
batches are faster than its first batches, so the short run does not establish
steady-state convergence or statistical significance. No garbage collection is
forced. Peak RSS is process high-water memory, including setup and warmup.

`pass: true` in the raw timing report means every worker and semantic/hash oracle
completed successfully. It is **not a performance guard or promotion verdict**.
The global candidate is rejected because of the check-only costs and incomplete
output coverage; the measured compile-preparation benefit motivates a separate
output-policy experiment.

## Preserved identities

[timing-audit.json](timing-audit.json) rereads all recorded API/runtime/harness,
configuration, exposure and fixture paths and compares their current bytes to
the captured identities. It also checks each worker's source hash, Node version
and reported CPU affinity. All 33 observations pass. This after-run preservation
audit does not replace the worker's before-run input checks and does not claim
protection against arbitrary external mutation during execution.
