# Native Array dispatch within a closed local row

The disposable native-call extension passes the retained complete-state,
aliasing and public fallback checks, plus independent mutating-marker and
deferred-result review. Maintained confirmation shows an 8.2% incremental
throughput gain; no compiler integration follows from this prototype alone.

The prospective design is
`design/phase30/closed-owned-row-native-calls.md`. The exact derivative in
`prototype-owned-native-01` starts from the checked first ladder's private-row
module. It changes four root allocation sites, four private cell read sites
and one deferred setter site. Generic gen/init setup, every public definition,
all array helpers/checks, records, project/copy, arithmetic and root forcing
remain unchanged. Complete non-tail native results still pass through force;
the setter remains inside the same saved-alias Dp field thunk.

The prior private variants explicitly assumed standard Array intrinsics. Static
independent review identified that a marker getter on Array.prototype can mutate
G during native-result forcing. The new variant therefore adds one outer
eligibility check rejecting Array.prototype request/bounce/build/code hooks or
a changed prototype parent. It falls back for the entire probe, before private
work, without adding a per-native-call guard. The old limited-domain variants
and their evidence remain unchanged.

`prototype-owned-native-controls-01` passes 28 independently calculated complete
four-array points across all six modules, 20 alias/freshness/zero-swap cases,
257 ordered host observations and 20 admission checks. The original control
actions and assertions are retained; adaptation only adds the new variant to
the existing loops. These include raw/forged/constructed entry, saved partials,
descriptor mutation, copied-length behavior, primitive marker hooks and each
native descriptor changed before first probe use.

`prototype-owned-native-counts-01` passes 20 separate instrumented runs. At
size 32, seed 17:

| Operation | Prior private row | Plus direct native calls |
| --- | ---: | ---: |
| Generic apply | 794 | 630 |
| Jump | 227 | 195 |
| Force | 600 | 600 |
| Function descriptors / partials | 367 / 264 | 367 / 264 |
| Projection / private copied slots | 258 / 384 | 258 / 384 |
| Allocation / array read / array write | 4 / 128 / 129 | 4 / 128 / 129 |
| Build / constructor | 33 / 34 | 33 / 34 |
| Region guard / private entry | 1 / 1 | 1 / 1 |

Exactly 128 reads, 32 cell writes and four allocations bypass native descriptor
application; the 32 setter bounces disappear at their original field demand.
Storage and forcing counts stay fixed. These are mechanism observations, not
measured cost shares or a performance result. Generic setup remains a fixed
residual. All derivation/control/count outer receipts retain complete outputs.

Independent `review-owned-native-markers-01` passes 27 additional observations:
12 marker-hook cases and 15 native getter/in-place mutations before first use.
It also retains a real historical scope counterexample: an Array.prototype
bounce getter changes umin's result during Tuple forcing. The old private-row
variant then computes different complete arrays; the original generic and new
native variant agree because the new outer check refuses private entry. This
is outside the old variant's standard-Array scope, not a retroactive assertion
of universal correctness for that artifact.

Independent `review-owned-native-deferred-01` passes 27 raw/constructed delayed
forcing, repeated saved-bounce, shared-handle, proxy and foreign-array
observations. Both independent reports are bound in the frozen
`prototype-owned-native-plan-01/{screen,confirm}.json` configurations. Those
compare generic, prior private row, new native and pinned TypeScript on the
same full-state size-32/seed-17 point, with unmodified standard prototypes.
Under the parent's exclusive CPU3 grant, `owned-native-screen-01` completes in
8.28 seconds with every output passing:

| Variant | Median ms | Sample range ms |
| --- | ---: | ---: |
| Generic baseline | 0.869710 | 0.868640–0.878913 |
| Prior private row | 0.557445 | 0.553356–0.608188 |
| Plus native calls | 0.490638 | 0.489739–0.491511 |
| Pinned TypeScript | 0.009223 | 0.009202–0.009519 |

The apparent incremental gain is 1.136×, but this is only screening evidence.
Generic half changes are +46.4% to +48.7%, prior row −12.15% to −0.03%, new
native −13.3% to −11.8%, and TypeScript −10.9% to −8.4%. Keep the full raw
screen rather than using its larger apparent gain as the final result.

The unchanged maintained confirmation, `owned-native-confirm-01`, completes in
84.53 seconds with all outputs passing:

| Variant | Median ms | Sample range ms |
| --- | ---: | ---: |
| Generic baseline | 0.598737 | 0.577021–0.619028 |
| Prior private row | 0.368370 | 0.365618–0.377833 |
| Plus native calls | 0.340405 | 0.336263–0.351977 |
| Pinned TypeScript | 0.008387 | 0.008374–0.008450 |

The native step gives **1.082× throughput**, or **7.59% less time**, against the
prior private row, with disjoint ranges. The full ladder is **1.759× faster**
than the generic baseline but still **40.6× slower** than pinned TypeScript on
this complete fixture. Within-process changes are generic −2.09% to +3.59%,
prior row −3.16% to −0.14%, native −1.26% to −0.06%, and TypeScript −0.73% to
+2.21%. The confirmation is substantially more stable than the screen; retain
its ranges and residual drift rather than treating the median as exact.

Native descriptor dispatch is a measurable piece of the gap, but removing it
alone is insufficient. Generic setup, record projection/copies and deferred
build/force administration remain unchanged. A production extension still needs
the general locality/admission proof and broader source coverage. This
experiment intentionally stops before representation specialization or setup
loop changes.
