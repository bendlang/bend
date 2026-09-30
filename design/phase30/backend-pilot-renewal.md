# Renew selected backend evidence on the final compiler

This is a prospective validation campaign, separate from the clean performance
matrix and installed-release gates. Reuse the Phase24 deterministic selection,
unchanged census helper and frozen paired harness. Do not add sources, backend
lanes, platform probes, network fixtures, ThreadSanitizer or GPU execution.

Bind the exact final attempt manifest/API/runtime/Base, Node, retained upstream
pin, Phase24 selection/inventory, helper and Clang16 environment in a fresh plan.
Run only `candidate` mode, which verifies the attempt before and after each
batch. The historical plan's original API hash describes its selection-era
baseline; it must not be reported as the new compiler identity.

First run the seven pilot batches, indices0–6, serially, under a single
900-second outer campaign deadline. Retain the existing four-job CPU3–6,
30-second per-probe, 4-GiB heap, 4-MiB stack, 420-second per-batch limits. A
parent process-group supervisor bounds the entire helper/harness/worker tree
by the remaining campaign time and retains stdout/stderr/status on timeout.
Fresh directories and unchanged fixture order are required.
At the deadline, request termination of the owned process group, then allow
at most three seconds of cleanup grace before SIGKILL. Record that grace
separately from the campaign work budget; it starts no additional work.

The expected pilot is 81 exact comparisons: 28 interpreter, 26 JavaScript,
23 native C and four checking rows. The four checking rows retain shared raw
failures for fixtures that reject at later emission; they must not be relabeled
as passes. Require the same four named rows and exact paired observations.
Require all77 execution rows to pass on both sides. Stop on a new incomplete,
missing or nonexact observation and retain all later rows as unexecuted.

The historical helper can leave `complete: true` before a later verification
or archival exception. The new supervisor therefore additionally requires no
error, an empty changed-input list, and a verified archive receipt with matching
archive hash and file count. It preserves partial saved rows and raw selected
JSON identities on interruption. Rows in an interrupted batch are explicitly
incomplete with completion unknown; only never-launched later batches remain
unexecuted. Cleanup terminates a still-active child process group on unexpected
exceptions as well as timeouts.
Cleanup also checks the owned process group after its leader exits, so an
abrupt helper exit cannot leave an untracked worker or native child behind.

No other selected/frontend/backend harness may concurrently use the same
fixtures' temporary paths. No clean timing window overlaps this campaign.
The current source inventory and normal reference fixture oracles remain
authoritative; do not replace errors or outputs with normalized comparisons.
Archive each newly produced selected tree through the helper's existing
verified compression/readback operation. Preserve old archives unchanged.

After the pilot passes, the root may separately authorize the retained broad
JavaScript selection: exactly13 `js-*` batches and811 additional rows from the
same Phase24 plan, each at most64 rows. Selection order, original per-row and
per-batch limits and `retain: failed` remain unchanged. This extension runs no
additional interpreter/native/platform lane. All811 rows must appear explicitly
as complete or unexecuted; there is no silent truncation or dropping.

Freeze the broad campaign separately with a prospective 1,800-second outer cap
unless the root chooses a smaller limit before execution. This is a ceiling,
not authorization to use that time before release priorities. Execute batches
serially and stop at the first new incomplete/nonexact/failing row to triage.
Expected speed is only an estimate until acquired. The historical pilot's22 JS
rows took24.70 seconds of paired child work; a linear extrapolation suggests
roughly15 minutes for811, but broader sources and archival work may cost more.
The cap and explicit unexecuted remainder prevent that estimate becoming an
unbounded commitment.

The root grants each campaign separately after final selected gates and clean
measurements. Plan creation executes no compiler. Even a successful pilot plus
all811 additional JS rows is scoped backend evidence; it does not imply full
native/IO/platform/backend conformance or independent proof-kernel checking.
