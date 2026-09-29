# C1: observe group-comma eligibility and first-error order

Prospective diagnostic-only controls, frozen before probes. Parent is the
installed Phase20 checked attempt `import-diagnostic-build-04`, selected API
`40c8f7f3b7cd0e96aef57d7d574ebfd85607cd4e096909d083b450b4d973362c`.
Reference remains pinned upstream `b2111cf`. This follows the committed
`group-boundaries.md` C1 proposal; no compiler source/build/ABI change is allowed.

Freeze an explicit parse/check selection before running the unchanged paired
conformance harness. Retain original `group/body-comma` and all eight saved
rejected-stage fixtures with their original IDs/bytes (18 observations). Add
21 independent neighbors (42 observations): scalar/nested tuples; completed
local and parallel tuple components; raw local/parallel/typed-local commas;
invalid pattern, earlier RHS and later continuation/tuple errors; grouped Match
heads, row patterns and later row syntax; and a valid ungrouped Match control.
The preparation tool binds exact fixture, selection, design, API and pin hashes.

Predictions to test, not assumed outcomes:

- Raw local or parallel bodies followed by comma reject at comma after their
  earlier semantic checkpoints. A completed inner local group may form the
  first element of an outer tuple. Ordinary tuple syntax remains valid.
- Invalid local patterns reject before continuation/comma, but an earlier RHS
  syntax error wins. A raw-body comma rejects before parsing a later tuple
  component; an admitted outer tuple reaches that component.
- Grouped Match flattening rejects an ineligible head before a closing/comma
  error, but row pattern/syntax errors happen before that flattening boundary.
  Saved grouped/ungrouped row witnesses retain their distinct failure order.

Explicit acceptance/rejection expectations are fixture hypotheses. A wrong
fixture or expectation remains a failed original attempt; any correction uses
a new preparation/selection. Preserve full raw paired diagnostics, verdicts,
phases, checked flags and process metadata. Reference oracle pass, observed
agreement and candidate raw suite status are reported separately. Do not count
a healthy but mismatching collection as conformance success.

Use the existing Phase18 paired runner unchanged, with the immutable Phase20
attempt's own workflow/host/harness. It runs CPU3, Node24.18, stack4MiB/heap4GiB,
one persistent worker and fresh output directories. Check child errors, signals,
timeouts, missing rows and worker health beyond aggregate exit status. Elevated
process permission is already authorized for these probes if required. No
broader sweep, timing claim, source mutation, architecture implementation, commit
or push belongs to this bounded approximately15-minute task.

The result should decide whether a naked raw-tag comma guard would regress
valid nesting or earlier errors. Report the smallest information that must be
preserved at the existing group owner, rather than implementing another parser
or validator. Stop after this evidence and a narrow recommendation.
