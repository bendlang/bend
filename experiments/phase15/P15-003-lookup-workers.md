# P15-003a: source lookup decisions without intermediate messages

Prospective candidate plan,2026-09-29, after the released-image profile and
before any candidate edit, component build, counter probe or timing. Parent
[P15-003](P15-003-checker-speed.md) retains its01:31:44UTC feasibility deadline.
Owner: phase15_speed. Outcomes: [checker-speed report](../../implementation/phase15/checker-speed.md).

## Measured selection and hypothesis

`selfhost/build/phase15/speed-profile-01` profiles verified Phase14 combined-01
API9136be92 on its unchanged full source. All process/result/input gates pass.
Of2551exclusive samples, lexical lookup ownership is4.3728%,index_find3.7872%,
norm_match3.0319%,check_node2.0906%; GC14.0985% and run_loop12.2118% remain
unattributed overhead. No share is a recoverable-gain forecast.

Select only `src/core/term.bend:lookup`. Its cache-sentinel decision uses a
selected closure/Unit/message and ordinary-list name misses retain another
Unit/message despite version5 lowering. Two Boolean-parameter workers may
expose the existing recursion as a generated mutual-tail loop, avoiding
intermediate choices without a new representation, index or JS helper.
Expected cost is approximately25extra Bend lines and two definitions. This is
a performance tradeoff; no line-count reduction or speedup is yet established.

## Invariants and falsifiers

Keep the Nil test, head/tail projections, cache-kind comparison, name comparison
and selected call in exactly the same demand order. A BookCache sentinel must
win before examining its ordinary name or remaining declarations. Ordinary
lists remain first-match-wins, including duplicates, empty names, unusual kind
strings and misplaced cache markers. Misses return the same missing shape.
No hash, child, bucket, cache construction, put/update, freshness bound or public
API changes. Do not alter the installed normalizer or guarded JS helper.

Any observed demand/error/complete-result change rejects the candidate. Inspect
the actual checked emitted loop; source resemblance is insufficient. Native
stack behavior is tested under original limits/history, not inferred. Malformed
raw data/getter controls establish only their explicit finite scope.

## Gates before performance

1. Freeze isolated project copied from verified Phase14 snapshot, exact before/
   after source, tool and config. Change only lookup and its two private workers.
2. Build both small upstream-checked core components. Compare existing5769index
   controls plus tailored raw-list/cache/duplicate/Unicode/error-order/deep-list
   controls. Preserve selected errors and side-effect read order.
3. Build a genuine checked B1 with unchanged equality-v5 and26focused cases.
   Full result differences may include only declared snapshot relocation.
4. Instrument copies to count selected closures, Unit objects, messages/arrays
   and total trampoline dispatches on valid two-module4/16/64definition graphs.
   Complete loaded/check results must be exact. Counts are not timing evidence.
5. Run the generic current-host paired fresh-string and exact53/60request
   histories versus Phase14 under4MiBstack/4GiBheap, no added recycling.
6. After independent source review and root's exclusive timing grant, fresh-
   process ABBA on the exact unchanged Phase14 full source, CPU0, same Node/
   host/runtime/Base policy. Preparation excluded; complete ordinary results
   exact; every execution failure retained. Record two samples per image and
   RSS, with no confidence-interval or TS-ratio claim.

A modest gain can justify two simple workers; a noisy/no-gain result is deferred
rather than expanded into other families. Root owns combined conformance
history/full frontend/backend/release gates and the final TS comparison.
All consumed tools, original failures and artifacts remain durable evidence.
