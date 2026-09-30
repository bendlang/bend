# Restrict the array ablation to non-tail calls

Agent-generated prospective amendment, before deriving or timing any array
prototype. This supersedes the tail-site permission in
[native-array-call-ablation.md](native-array-call-ablation.md).

Independent review and the lead identify an ordering error in that prospective
permission: `jump(f,args)` defers the native operation until forcing. A caller's
oversaturation length checks can run between jump construction and the native
array's getter/mutation effects. Returning an immediately computed raw helper
result therefore does not preserve that boundary. Raw descriptor callers can
also retain an unforced bounce.

The first ablation changes only syntactically non-tail `call(get(G,"Array.get"),...)`
or `call(get(G,"Array.set"),...)` sites. Every `jump` stays byte-identical. In the
selected edit-distance cell chain, this means the four Array.get sites; Array.set
inside the scheduled constructor field remains unchanged. Exact new/set/size
recognition and tail specialization are deferred.

Every direct non-tail helper result still passes through `force`, as specified
in the original plan. Current target capture precedes arguments and the descriptor
guard follows them. All other source, ownership, live-G, erased-slot and foreign
array boundaries remain. Keep both old/private baselines and fixed/guarded
Array.get variants; the six-variant frozen timing protocol remains appropriate.
No timing starts before the lead's exclusive grant and required semantic review.
