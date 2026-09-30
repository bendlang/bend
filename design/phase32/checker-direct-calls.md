# H17 structured-helper direct-call ablation

Prospective Phase32 plan, 2026-09-30. Owner: checker experiment agent.
No production compiler edit or timing has occurred under this plan.

The Phase31 checker profile points to generic application/forcing and the
lookup/index chain. `lookup_cached` is present in22.3% of inclusive samples;
that is an overlapping lead, not an attributable cost or promised speedup.
Use the actual H17 module identified in the Phase31 profile, SHA
`a7ffece566086a00c7b8224680ab320f1933e7ae7663fc765ed20eea5c8cdeb5`.
This is the generated Bend compiler, not the handwritten TypeScript compiler
or installed checked07. There is no new self-emission claim.

## Smallest hypothesis

For a known exact unary record projection, replacing emitted
`callOwned(get(G,name),[argument])` by `force(private_code([argument]))`
may remove material call administration inside lookup. Copy the exact original
callback body: retain `project`, `slice`, field layout, field snapshot order,
argument evaluation and result forcing. Do not inline record reads, remove
force, change matchers, widen recursive-type admission, or fuse recursion.

The first family is `lookup`, its two dispatch helpers and the existing
index-find/child/hash/bucket path. All recursive calls retain the unchanged
runtime trampoline. Its eligible unary callbacks are KDef projections
`dn,dk,da,dx,dt,dv,dc,db,du` when present. The second independent structured
helper is `infer_ref`, using the same KDef projections and eligible fixed
KEnv/KChecking/KWorld projections. Its nonprojection dependencies remain
ordinary calls. This exercises result construction and success/error branches,
not merely another spelling of lookup.

Derive three diagnostic entry sets from the saved original module: original
public functions, private copies with unchanged calls, and private copies with
only the saturated unary callback replacements. The original module is a
byte-for-byte prefix; all existing G definitions and default exports stay
unchanged. Private copied recursive references resolve within a separate
namespace. Record every copied definition, exact callback, replacement count,
module hash, complete source prefix identity and derivation-tool identity.

## Scope and proof boundary

Private experiment entries require the harness's ordinary, immutable, finite
constructor graphs and unchanged dependency descriptors. These are not newly
admitted public roots. The original public API still takes its original path.
A guard only at a public structured entry is insufficient: a record getter can
replace G.dn after admission. Keep a discriminating getter mutation witness and
prove all original public entries retain its observation. A successful private
experiment therefore does not authorize dropping public descriptor checks.

A production route would reuse the existing region proof only for data proved
internal to a closed graph, or establish an equally explicit trusted boundary.
Open recursive input types, host getters/proxies and unknown callbacks remain
hard blockers. If per-call descriptor checks are needed, measure them as a
separate candidate rather than treating immutable-image speed as production
speed. No emitter implementation is authorized by this hypothesis alone.

## Correctness before timing

Use an independent JavaScript map/list oracle with deterministic names, empty
and duplicate keys, prefix/non-ASCII/astral names, misses, and an explicit
32-bit hash collision. Compare complete KDef graphs, retained book graphs and
input identities for cached and uncached lookup, not checksums alone. Bind
index construction to the unchanged original H; oracle lookup is independent
of its tree shape. Check both existing and newly replaced definitions.

For infer_ref, independently predict undefined-name and family diagnostics,
demand-zero success, unfilled-law refusal and ordinary populated-definition
success. Compare the entire KChecking graph and retained world identity across
original and both private entry sets; retain complete observations. Include
multiple KTerm shapes and distinct worlds/definitions. Unsupported deep
specialization remains outside the selected oracle.

Check ordinary public descriptor mutation, field getters, saved partial calls
and raw callback behavior against the original module. Since the original is
an exact prefix, these checks establish the intended isolation; they do not
make the private entries safe for arbitrary host values. Deliberately wrong
projection index and premature getter capture must be rejected by the oracles.
An independent reviewer must inspect both private transformations and the
complete selected results before timing promotion.

## Measurement and stop rule

First acquire controls only, on a root-granted CPU. Timing requires a separate
exclusive root reservation. Freeze exact tools, modules and fixture graphs
before that reservation. Time complete batches of cached and uncached lookups
and infer_ref, with graph construction outside the interval and full value
checking outside timing. A fresh process loads one artifact. Rotate baseline
and direct variants serially; record all warm/calibration/sample observations,
median/range, half drift, Node version/flags, affinity, elapsed time and RSS.

Start with a short bounded screen, then confirm only a result exceeding5%
without a correctness discrepancy. Do not infer whole-compiler improvement:
this is a private helper experiment, and inclusive profile share is not an
Amdahl fraction. An unchanged or slower result rejects this isolated rule;
record it before considering projection elimination or a larger call graph.
Preserve failures and consumed tools in fresh phase32/checker-* paths.
