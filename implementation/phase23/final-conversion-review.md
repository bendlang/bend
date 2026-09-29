# Final Phase23 conversion and profile review

This review binds the final `combined-build-03` source and images. The equality
implementation's author performed the graph self-review; the same reviewer was
independent of the root-owned profile6 change. The lead separately reviewed the
graph change in [root-review.json](root-review.json). These roles are not a claim of independent authorship review of
one's own implementation.

| Input | SHA256 |
| --- | --- |
| `src/core/normalize.bend` |`4845ff63f3c228abc9a432410ddc8b7e20bfce27e54d6d49412b06608f7ce702`|
| `src/core/graph.bend` |`85625049b316ede08eeffd7ff509483183624f1197c582c9d1bb2cd8bebf4802`|
| `tools/development/equality.mjs` |`4260f1d04020326b3e8896cb44851c84ea2b2f6b950744ed22538cff9a7911c5`|
| Genuine checked API |`5f539f81bace8e5783a7cdd8c82606e106fe85813638d7725bff84a943d57c8a`|
| Derived API |`5596f914fd245a5085a614b81099360aeaf601ed61f16357fc491c85106c1102`|
| Derivation report |`a9048c97225bcaaf08f99fafaa5319c279d10df6d0cf5554c14fd252a5145ee1`|
| Attempt manifest |`6596a1b7f3cdcc72e95bba5fac7fae639e8e48f0db7a07e11da49bced978d40f`|

The maintained files, final snapshot and first combined snapshot have identical
bytes for all three reviewed source files. The earlier component/direct-control
results therefore continue to test the same conversion source; the final full
frontend acquisition separately checks the final complete image.

No correctness or complexity blocker was found in this bounded review:

- A `KNormShare` item is queued only for an `EQ` pair of original graph cells.
  Both cells are forced first. The item follows their child obligations, so it
  cannot install an unproved equality. `EQ` remains `EQ` in all descendants;
  kind alternatives arise only under directional `LE` and cannot manufacture a
  successful EQ continuation from a failed proof.
- Failed obligations jump to saved alternatives, discarding unfinished sharing
  continuations. Previously completed EQ proofs and evaluation results remain
  valid under the unchanged immutable book. A heap's cell identifiers increase
  monotonically; rigid/full passes and independent conversions receive fresh
  heaps. Sharing copies an already forced value instead of creating cell aliases.
- Lambda and telescope opening keep the existing fresh-variable bound. Only the
  telescope domain is newly shared; its codomain remains available to ordinary
  binder substitution. The existing explicit worklist keeps deep structural
  comparison off the host recursion stack.
- The implementation adds one worklist constructor and six small workers across
  existing modules. It reuses `GState`/`GHeap`/`GResult` and `g_wnf`; it does not add
  another normalization representation or global cache. Ordinary `wnf` remains
  for other checker queries. Initial syntactic comparison can still do work
  proportional to the supplied syntax: these tests do not prove bounded cost for
  every arbitrarily constructed reflective host value or divergent unsafe term.

The [profile review](profile-review.md) remains applicable to the identical
profile6 bytes. The new dependency closure, same-runtime profile selection,
bootstrap lineage checks and historical byte replay have no new changes in the
final source. Its native primitive-string guard assumes ordinary unmodified
JavaScript built-ins; no universal reflective-host transformation claim is made.

The [frontend validation report](frontend-validation.md) owns final image results.
Backend execution, request histories, release relocation and controlled timing
remain separate gates owned by the lead and backend reviewer.
