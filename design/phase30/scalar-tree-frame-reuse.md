# Reuse private scalar tree frames by depth

Prospective isolated output experiment after actual12. Its private depth-first
tree creates a fresh `{args,phase,left}` record and argument array for every
internal node, then truncates the stack backing array on pop. For the retained
small original program there are 255 internal nodes but a maximum depth of eight.
All saved arguments and child results are scalars, and the frames never escape.

Keep a backing pool for the duration of one private tree invocation. On push,
reuse the frame already stored at that depth if present; overwrite every saved
parent argument, reset phase to zero and left result to null. Otherwise allocate
the same original frame and argument array. Advance the logical top in the same
place. On pop, decrement only the logical top; retain the backing entries for a
later sibling. The pool remains local to one invocation, so distinct public
calls share no mutable private storage.

Derive only from the original checked attempt12 Mandelbrot output and its
verified receipt. Change the one private rcol push statement and its pop
statement. Keep guards, exact entry, helpers, primitive expressions, order of
left/right/combine, immutable source aliases, original zero behavior, BigInt
counter and fallback byte-identical. The push stays after the original left
argument computations. Save parent aliases, not those computed child arguments.
Do not use typed arrays, flatten frames, retain pools across calls or change any
public record/array representation.

The proof depends on the current tree admission: every frame slot is a native
scalar, no deferred computation or container reference captures its args array,
and private helpers cannot observe the frames. Reusing a frame would be invalid
if a closure or returned record retained it. The logical top governs traversal;
no remaining code may use pool length as the active stack depth. Check that all
args positions are overwritten before reuse and that both phase and left result
are reset. Stable Array/host intrinsics remain the explicit scope: a numeric
Array.prototype accessor could observe the new pool lookup and is outside this
existing private-storage contract.

Before timing, run the unchanged tree scalar/original-program oracles, full
ordered public/descriptor/entry/copy observations, independent supplemental
marker/metadata suite and post-guard depth sentinels. Compare repeated calls with
different arguments. Instrument copies separately to record pushes, fresh frame
and args allocations, reuse count, logical high-water, visits and complete leaf
index traces. On the original small point, require 255 pushes and eight fresh
frames with 247 reuses, retaining the exact scalar result and traversal. The
instrumentation must snapshot counters before later checks can mutate them.

Freeze paired original-program and cheap tree-adapter configs only after these
gates. Keep actual12 unchanged and frame reuse as the sole variants. This is a
disposable representation-lifetime experiment, not a production edit. Report
source size and both first-call and settled timing; do not infer speed from the
allocation counts or multiply gains with the earlier tree experiment.
