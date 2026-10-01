# Skip private inlining when its rewrite rule cannot match

The Phase35 normal checked request cost rose 8.17% for Mandelbrot, 30.09% for
symreg and 34.40% for ray tracing. These measurements identify a problem, not its
cause. The proposed first ablation removes an identity traversal and requires
byte-for-byte identical emitted programs before a compilation-speed claim.

`j_region_declarations` currently invokes `j_region_inline_defs` for every proved
private closure. That pass traverses and reconstructs every non-residual helper
term, with a separate 2,048-node budget per helper. Its only rewrite admits an
original helper whose kind is `Def`, which is not native, whose body has tag `Ann`,
and whose annotated result satisfies `j_region_local_vector`. Scalar helpers and
structural folds cannot trigger it. A failed traversal already keeps its original
helper unchanged.

Add one short-circuiting scan of the bounded helper list, using exactly those
four existing eligibility predicates. If no helper qualifies, send the original
helpers directly to `j_region_definitions`. Otherwise run the existing pass
unchanged. Do not change the region proof, budgets, helper order, guard names,
public descriptors, fallback, output naming or generated runtime.

The proof is narrow: when that predicate is false for every original helper,
`j_region_inline_children` can only call `k_with_children` with recursively
unchanged children. That constructor preserves every other immutable field,
including source spans, lambda representation and removed-name metadata; literal
nodes are returned unchanged. Budget failures also select the original value.
Native and `JResidual` entries remain guard dependencies and keep their current
emission behavior. The scan does not inspect caller terms or change any admission
decision. Compiler-internal object identity is not an emitted observable.

The proposed source patch is [cost-preflight.patch](../../implementation/phase36/cost-preflight.patch).
It adds 11 physical lines and one definition, not a cache, global optimizer state,
new IR or runtime branch. No source file is changed by producing this patch.

## Expected opportunity and falsification

The frozen checked09 modules contain five Mandelbrot private closures / 31
declarations, four symreg closures / 31 declarations, and four ray closures / 29
declarations. Their emitted private helper signatures return scalar values;
residual producers remain generic. These counts motivate a test but are **not**
measurements of optimizer visits or CPU time. Pair has two closures / 47 private
declarations and fold has one / seven, including vector paths that must keep
their current inliner. The type predicate, not a benchmark name, makes the choice.

Provisional gain estimate: 0–5% of a normal scalar/fold checked request, with low
confidence before the ablation. This is deliberately smaller than Phase35's
whole regression; repeated type/purity analysis may dominate instead. Pair/fold
may incur a tiny extra bounded scan. Reject if any emitted module differs, if
controls find a lost vector inline, or if request timing shows no useful gain
with a material vector-case regression. Preserve null results.

## Sequential test

1. Root applies only this patch to a checked Phase35 baseline in an isolated
   attempt, builds with the established B1 workflow and Focus36, CPU3, one GiB
   Node heap, RSS/deadline supervision and the shared lock.
2. Run [cost-inline-controls.mjs](../../selfhost/tools/performance/phase36/cost-inline-controls.mjs)
   against checked09 and the new checked API. It adds diagnostic exports and a
   visit counter to copies only. Check empty/scalar/native/residual/fold helper
   sets, non-Def refusal, positive vector cases, source metadata, and budget
   fallback. This is not timing and does not run benchmark programs.
3. Prepare the unchanged maintained 15-point catalog. Require exact emitted-byte
   equality against checked09 for all 13 unique source compilations and their
   catalog adapter modules, accounting only
   for the already documented driver/Base-directory path identity by acquiring
   both attempts through the same checked workflow. Do not normalize timed output.
4. Run the existing normal checked request worker, held constant, on pair,
   Mandelbrot, symreg and ray. Use three rotated fresh-process samples, ordinary
   validated Base cache, request and import-plus-request boundaries, and retained
   output hashes. Do not substitute emission-only timing.
5. Keep an isolated cost-only comparison even if guard/producer improvements are
   combined later. Combined generated modules may change for independent reasons;
   they cannot serve as the exact-byte preflight ablation.

The fastest discriminator is step 2 plus an exact Mandelbrot module comparison.
With a 42.5-second previous checked build and roughly six-second supervised
compilations, a small answer should be available in minutes. Broad validation
belongs to the surviving combined compiler, not each identity-pass experiment.

## Deferred alternatives

The prior AST inventory found 26 pair private declarations (21,160 bytes) and five
fold declarations (1,783 bytes) with no direct call under their names. Deletion
needs actual private-plan reachability from the root after inlining, including
`JReadCall` bridges and calls in emitted helper bodies. Guard dependencies must
remain even when their declaration disappears. This would add a liveness pass,
change output, and may cost compilation time; do not bundle it with this cheaper
identity-pass test.

Likewise, caching successful purity graphs is plausible but changes fuel/cache
boundaries and must not treat a partially checked SCC as proved. It is a separate
experiment after visit counts show repeated successful proofs dominate.
