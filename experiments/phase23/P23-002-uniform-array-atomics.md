# P23-002: shared arrays over the existing uniform slot ABI

Status: prospective plan, authorized after the initial Phase23 cost screen.
Owner: phase23_backend. Target0187512; initial combined-build-01 stays frozen.

The new `spin_array_hold` and `array_redirect_race` execute successfully upstream
but fail in both candidate backends because Array.atomic.add has no intrinsic.
Their original16-row backend gate is retained as failed. This is an inherited
execution gap exposed by the new regressions, separate from the pin fixes.

Hypothesis: the existing term_keep/RFC redirect ownership machinery supports
shared array handles without a new representation. Make array consumers use
term_peek, retain fields when a shared block is split/copied, and decrement a
shared block through term_drop. Preserve one64-bit slot per element. Array.fork
and join remain checked Base bodies using the existing sharing/dropping emitter.

Add all nine Base atomic operations through a CAS loop over the U32 payload of
the existing slot; fadd preserves F32 rounding and bit encoding. JavaScript uses
one synchronous read/modify/write step, preserving its current sequential model.
Names are recognized only through existing Base-provenance intrinsic policy.

Owned additional sources: back/native/array.bend, back/native/bridge.bend,
back/js/emit.bend, runtime/js/base.mjs and the already-owned runtime.c/runtime.mjs.
No packed-array layout, new graph/IR, global cache or bootstrap-profile edits.

Acceptance: all nine atomic operations with old-result checks, wrapping indices,
U32 overflow/CAS success/failure/F32 boundaries; alias visibility, clone isolation,
shared split/leaf-copy retention and drop/join; two exact upstream regressions;
repeated workers1/2/3/4 on forked updates; retained array/backend controls. Inspect
emitted C and native ownership independently. Any corruption, lost updates,
new discrepancy or unexplained resource failure rejects promotion. Keep failed
attempts and do not raise limits to hide them. ThreadSanitizer and GPU results
are separate evidence; no claim without an actual successful run.
