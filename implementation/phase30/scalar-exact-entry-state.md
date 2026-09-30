# Exact permission without a per-invocation record

The isolated attempt12 output ablation passes its semantic controls. It replaces
the private `{code,args,used}` permission record with three private scalar slots,
saved in local variables and restored in the existing `finally`. All permission
decisions, property reads, registration checks, invocation and body code remain
unchanged. No maintained runtime or compiler source has been edited.

The design is `design/phase30/scalar-exact-entry-state.md`. Only the current
permission can be consumed, synchronously before any user argument read. A
suspended permission cannot change while another permission is current, so its
saved consumed bit can be restored by value. This avoids the record allocation
without changing the separate method/prototype eligibility policy.

`review-entry-state-source-12` is a fresh checked emission of the maintained
scalar helper through immutable attempt12. The original edit-distance emission
comes from `transfer-12/editdist`. Both checked receipts, exact changed text,
source identities and unchanged-byte assertions are retained in
`review-entry-state-01`.

| Complete module | Bytes | SHA-256 |
| --- | ---: | --- |
| Scalar unchanged | 82,259 | 990a2a7568cdb40541883237b97e008ee785a8d8e890400b9890fe21274204f5 |
| Scalar permission slots | 82,467 | 5bf0c23a46d28ff71918942f16f1a275bdee654a5b87bd133b70aeecc365f7f9 |
| Edit distance unchanged | 82,492 | 10c684a5ff9768630848afd3b9ec455cc24fad3a265a37c7d095d1736afe3e32 |
| Edit distance permission slots | 82,700 | e03b722f95ef3f98d202047f701313342de6588284aa4de290d024ec19d1186c |

The 208 extra emitted bytes are the explicit slot names and save/restore
statements. The experiment removes one runtime object per registered exact
entry; it does not claim all entry allocation disappears. The Reflect.apply
argument array, wrappers and ordinary application vectors remain.

Fresh passing receipts under `selfhost/build/phase30/`:

- `review-entry-state-abi-01`: 146 ordered ABI/prototype observations and 72
  scalar oracle observations.
- `review-entry-state-entry-01`: nine emitted exact/raw/reentry cases.
- `review-entry-state-controls-01`: 121 independent fixture points, including
  50,000 iterations; 28 complete four-array row points across both variants;
  and 17 independently authored permission-state scenarios.

The targeted scenarios compare diagnostic permission flags as well as values,
raw error messages and event order. They cover same-code nesting, different-code
nesting, same-vector slot reentry, environment callbacks before installation,
caught/uncaught callback and slot throws, throwing environments, custom/getter/
throwing/noncallable methods, raw/forged calls, partial/overapplication, ordinary
and arrow callbacks, and deferred bounce/build execution after restoration.
The diagnostic exports are separate copies and never timed.

The frozen `scalar-{screen,confirm}.json` and `row-{screen,confirm}.json`
configurations use `[128,524800]` and complete edit row `[32,17]`, respectively.
Only unchanged and transformed complete programs are timed. Stable host
intrinsics retain their existing scope.

The parent's timing coordinator completed the frozen screens and five-sample
confirmations in fresh, serial CPU3 processes. Screens did not settle: the
scalar halves improved roughly 10%, while the row slot variant's later half
became roughly 137% slower. Those raw screens remain retained and are not used
as the final speed estimate.

| Confirmation, milliseconds per call | Original median [range] | Slots median [range] |
| --- | --- | --- |
| Scalar 128-step fixture | 0.00696923 [0.00695345–0.00697983] | 0.00675304 [0.00669688–0.00676914] |
| Complete edit row 32 | 0.332801 [0.328857–0.349670] | 0.346227 [0.334958–0.367940] |

The scalar point gains 1.032× with disjoint ranges and within-sample changes no
larger than 2.30% original and 3.26% slots. The row medians favor the original,
but ranges overlap and both continue improving within each sample: original
6.3–11.0%, slots 7.2–21.3%. This is no positive row evidence, not a settled claim
of a precise regression. First-call medians are 1.436/1.405 ms for the scalar
point and 6.372/6.360 ms for the row. Receipts are
`entry-state-{scalar,row}-{screen,confirm}-01`; confirmations took 41.89 and
42.09 seconds externally.

Decision: defer this change. A roughly 3% narrow gain with no row benefit does
not justify replacing the simple permission record with three mutable global
slots and additional restoration code. The maintained runtime remains
unchanged. Allocation removal alone was not a useful predictor of speed here.
