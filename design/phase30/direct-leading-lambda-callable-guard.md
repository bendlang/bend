# Phase30 follow-up: a function's mutable `.call` property

Status: prospective repair, written before executable counterexample or attempt02.
This supplements the frozen direct-leading-lambda amendment without changing it.

Attempt01's 103 selected observations did not exercise mutation of the captured
code function's own `.call` property. The runtime invokes `f.code.call(f.env,args)`;
the private extracted body bypasses that property. Merely checking the descriptor's
`code` identity is insufficient: its function object can acquire a `.call` method
or getter while retaining the same identity. Treat attempt01 as unpromotable
pending this counterexample and repair; no clean timing should be run on it.

Add focused controls for an own `.call` method, own `.call` getter and changed code
function prototype providing `.call`. Preserve old observations and record new
failing evidence separately. A new immutable attempt02 must require:

- no own `call` property on the captured code function;
- code function prototype equal to the captured ordinary Function.prototype;
- that prototype's own `call` remains the original data method.

Use property-descriptor inspection to avoid triggering a new accessor before
falling back. Check after argument evaluation, because argument effects can alter
these objects before the original invocation. Preserve ordinary descriptor and
G-binding fallback controls. The standard intrinsic assumptions still apply to
administrative Array copying; this amendment does not authorize new built-in
monkeypatch semantics.

A guarded result remains valuable even if guard overhead outweighs saved dispatch.
A separately planned closed pure scalar region could amortize verified metadata
at one entry boundary. It is a different experiment and must not replace the
per-call guarded result silently.
