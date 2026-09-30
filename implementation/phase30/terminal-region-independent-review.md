# Independent terminal-record region review

Static review of the prospective generated-JavaScript derivation found no
semantic blocker within the declared stable-host-intrinsics scope. This is a
review of the proposed transformation, not evidence that the compiler emits it
or that it improves performance. The experiment owner records acquisition,
controls and timing separately.

The reviewed files are
`design/phase30/terminal-record-nested-region.md` and
`selfhost/tools/performance/phase30/inspect-terminal-region.py`. The latter pins
the full attempt07 Mandelbrot output to SHA-256
`6c5ebcc9f07c0294e876754a6dce168fa0fee489fd2038bc56efe914d24abd3e`.

The derivation retains the original eleven successor slot reads before checking
entry permission, scalar inputs or the descriptor closure. Raw callbacks and
failed guards retain the original generic expression. A synchronous admitted
region receives only primitive scalars and reaches the eight snapshotted
descriptors, with no foreign callbacks or host input objects. The three newly
needed snapshots are taken while constructing hchunk, pix and bkt, rather than
on first invocation. The original five snapshots remain in place.

The outer worker starts with the already projected predecessor: its first pixel
is the original position plus that predecessor. The nested mit worker instead
receives the unprojected Nat count, handles zero before subtraction, and then
reuses the current private loop expression. It retains BigInt representation.
The public hchunk Zero branch is unchanged, including its ability at the host
ABI to receive non-scalar field values. The private terminal path binds immutable
final counters before returning the original build expression and its field
thunks. It neither projects the result early nor creates an eager record.

The acyclic-only variant forces the retained public mit tail at the original
caller demand point. The full variant rewrites only saturated known helper
spines, preserving nested primitive and argument text. The callback remains an
anonymous, one-argument ordinary function through the established exactCode
wrapper; Function source text is outside the ABI promise.

Requested controls include complete eight-counter oracles, saved Zero partials
with host field objects, deferred raw terminal builds, terminal field throws,
enclosing copied-length mutation and throws, raw/exact/reentrant entry, and
public callback reflection. The experiment owner subsequently reported all 200
complete histogram states and 129 boundary cases passing in
`selfhost/build/phase30/inspection-terminal-controls-02`. That is the owner's
execution evidence, distinct from this independent static review; no execution
or timing was performed by the reviewer for the terminal-region experiment.

For a later compiler implementation, keep the extension narrow: a terminal
closed constructor whose fields have scalar provenance, plus a separately proved
private Nat countdown helper. Preserve the existing private-expression emitter,
loop checks, graph bounds and runtime forcing. General record inputs, projection,
foreign calls and arbitrary recursive strongly connected components require
different proofs and are not admitted by this experiment.
