# Request-local emitter query reuse, prospective prototype

Initial diagnostic finds9,044/14,760 identical `wnf` argument pairs on original
edit distance,10,768/19,066 on Mandelbrot. Local-type repeats971/1,973 and
1,715/3,646; local-signature repeats281/366 and262/330. Root/region plans have no
identity repeats. Nested diagnostic times cannot isolate the107.77ms historical
compile regression. A large compact IR remains unjustified by these counts.

Prototype only request-local exact-argument identity reuse of resolved pure
`wnf`, `j_arm_type`, `j_primitive_type`, `j_nat_loop_native`, `j_nat_shape`,
`j_region_local_type`, `j_region_local_signature` and
`j_region_capture_eligible`. Use a Map trie including every argument, especially
book/type/mode/arity; clear it at each emission export's entrance/exit. Do not
memoize `j_region_local_check` with omitted active/fuel context. Resolve the same
trampoline result and store immutable semantic values; the source checker and
public runtime behavior are unchanged. The private prototype assumes the
generated Bend emitter's immutable data discipline; no external mutable input
API is added.

Compare full actual07 output/error/dependency observations on the fixed small,
original edit-distance, Mandelbrot and negative edit cases. Record cache entries
and hits. Only after equality passes, freeze a clean serial baseline/candidate
screen over normal complete requests with original Base cache handling, and
report request and emitter costs separately. Key construction and memory remain
inside the request. Bounded diagnostic producer120seconds CPU2; timing waits
for root grant. If useful, send a small shared-analysis proposal to the emitter
owner; this investigator does not change Bend production source. A saved-JS
memo's gain alone does not justify a new permanent IR or a public host cache.
