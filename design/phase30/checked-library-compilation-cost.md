# Compare the normal checked-library compilation workflow

The existing final check matrix times checking a frozen compiler source without
emission. Add a separate comparison that actually produces a complete checked
JavaScript library from each original Mandelbrot and edit-distance source.
This is a compiler-workflow measurement; it is not generated-program execution,
an isolated emitter microbenchmark, or a proof-verdict run.

Use pinned upstream TypeScript, immutable Phase29 attempt04, and a parameterized
final Phase30 attempt. Bind the final attempt and independently acquired output
receipts in a fresh prospective configuration; if attempt13 replaces12, create
a new configuration. Never edit the old one. Inputs are the exact sources and
checked emission provenance retained in transfer-12, with final output hashes
from that selected attempt's separately saved transfer modules. Each side must
reproduce its own independently saved bytes; different compiler output hashes
are expected and are not compared to each other.

For TypeScript, explicitly import pinned bend.ts and comp.ts, then time exactly
the normal library request: book_nil, book_load(input,"",new Map()), book_valid,
require zero holes, js_lib(book,true). For Bend, import that attempt's frozen
typed-driver.mjs, then time D.inspect(input,{mode:"library"}), requiring status
ok and checked true. Use its exact API/runtime/Base environment and existing
validated API-specific Base cache. Do not pass an API shortcut, preload the API,
select a private root, skip checking, invoke --verdict or create a persistent
session. Preserve each implementation's normal Base/cache pipeline.

Verify attempts, Node, source/Base closure, compiler modules, host driver,
validated cache and expected outputs outside the request. Explicit host-module
import time is separate. Default D.inspect performs lazy API loading inside the
request; TypeScript's explicit imports load its compiler earlier. Therefore
report both request-only and host-import-plus-request totals, describing them
as workflow boundaries rather than claiming equal stage attribution. The full
supervised child wall time additionally includes startup, identity validation,
output persistence and postflight validation; keep it separate. Preserve peak
RSS and each child's affinity/Node arguments.

Use fresh child processes on exclusive CPU0, 4 MiB stack, 4 GiB heap and a
180-second child timeout. For each source, run three samples per side in rotating
order: TS/Phase29/final, Phase29/final/TS, final/TS/Phase29. No calibration,
warmup request, prior in-process compilation or OS-cache flush. Normal disk Base
caches must already validate before the run; refuse a missing/stale cache rather
than quietly changing cache state for one measured sample. Use serial children;
the root must grant an otherwise idle timing window before launch.

Record and retain every emitted module, stdout/stderr, request, result and
supervisor receipt. Stop and preserve failure on a timeout, check failure,
changed input, changed cache or output-hash mismatch. Verify expected module
identity before and after each child, and verify all immutable input identities
at the end. For Bend, record the complete inspect observation separately from
the emitted code; for TypeScript record the successful zero-hole check. Return
medians, ranges and every sample for request, import-plus-request, host import,
process wall and RSS. Three fresh samples show a controlled comparison of these
two sources, not a broad compiler-throughput distribution.

The preparation tool accepts FINAL_ATTEMPT and FINAL_TRANSFER_DIRECTORY and
writes immutable config/worker copies. The worker exposes no benchmark shortcut
and uses the same calls as phase25/emit.mjs and phase26/emit.mjs. The runner must
be launched only after semantic gates and the parent's global timing release.
