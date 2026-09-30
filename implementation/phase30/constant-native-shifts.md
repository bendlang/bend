# Literal shift counts: a large, small-rule opportunity

The [prospective ablation](../../design/phase30/constant-native-shifts.md)
changes exactly two right shifts inside the private arithmetic-shift helper.
It leaves the BigInt countdown, helper graph, masks, public functions and guards
unchanged. All121independent points pass across four variants, including50,000
iterations; six raw-frame fallbacks and three saved partials also agree within
the frozen prototype's scope.

| Variant | Screen, ms | Confirmation, ms | Confirmation range, ms |
| --- | ---: | ---: | ---: |
| Phase29 fixture | 0.426154 | 0.400834 | 0.395029–0.434558 |
| Private region, dynamic shift lowering | 0.031545 | 0.028985 | 0.028697–0.030461 |
| Same region, literal shifts | 0.008908 | 0.007203 | 0.007180–0.007454 |
| Pinned TypeScript output | 0.001747 | 0.001706 | 0.001702–0.001712 |

The isolated change improves the long-window median4.024×, with disjoint sample
ranges. The resulting prototype is4.222× TypeScript on this point. Its combined
55.65× ratio against Phase29 includes the separate private-region transformation;
it is not a compiler-wide or representative-program speedup claim.

First calls are6.534/2.011/1.881/0.753ms in table order. The exclusive CPU3
screen takes8.231s end to end and confirmation84.464s. Both use rotated serial
fresh Node24.18.0 processes with exact results checked inside each call. The
confirmation uses five samples,100calls and3s minimum warmup,300ms timed targets.
The short window still warms substantially (region halves improve9.5–10.8%,
literal-shift halves21.6–22.1%). In confirmation the region stays within2.3%;
two literal samples vary by about6.1–6.2%, while the other three stay below1%.
This residual variation is small relative to the4× difference; retain both
windows rather than treating the short one as converged.

Decision: implement the narrowly scoped compiler rule and independently verify
it. Resolve compact native Nat literals after existing primitive provenance
checks. Counts below32 use the literal JavaScript shift; larger counts still
evaluate the left expression once before returning0. Dynamic counts keep their
current implementation. Actual checked compiler results remain pending.

Raw evidence: `selfhost/build/phase30/shift-01`, `shift-check-01`,
`shift-screen-01`, `shift-confirm-01` and launcher receipts. Derivation refuses
changed input shapes and preserves full modules and hashes. These prototypes
predate the corrected production entry contract and do not validate that contract.
