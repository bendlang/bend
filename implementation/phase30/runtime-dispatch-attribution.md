# Independent runtime attribution on held candidate14

Candidate14 is held after its complete original-program comparison exposed
generic-workload regressions. This report records two independent generated-JS
interventions. Neither is a maintained runtime change, a new compiler version,
nor evidence that the held release is ready.

The checked candidate14 API is
`ade96ba48b05ba116430f57e433d8fbdbd76646b61f5e9d53cf34a4c4a9da76d`;
its runtime is
`a3547a8854b45c65fd804f106868dc28540118b611d85fe99ba0e3d199c66ef0`.
Both derivations verify complete checked-emission receipts against that attempt,
require its exact runtime prefix, retain original and transformed module bytes,
and invert the substitutions to reconstruct the complete original module.

| Independent intervention | Changed mechanism | Public correctness controls | Decision |
|---|---|---|---|
| [Inline ordinary exact dispatch](../../design/phase30/inline-unregistered-exact-entry.md) | `apply` reads the selected code once and executes unregistered callbacks directly; registered callbacks enter the unchanged remainder of `invokeExact`. The WeakSet test remains once. | All acquired controls below pass. Private permission decisions remain unchanged. | Do not promote: confirmed row median is 0.610321 ms versus unchanged14's 0.606265 ms. |
| [Read the actual native method](../../design/phase30/actual-method-read-final14.md) | Only `invokeExact` changes, using the exact previously reviewed historical replacement. A registered callback's captured native `.call` value replaces conservative prototype/descriptor reflection. | All acquired controls below pass. An accessor returning the captured native method deliberately grants private permission; public observations remain equal. | Defer: confirmed row median is 0.547576 ms, 9.68% less time, but the selected generic-matcher intervention removes the same costly matcher-entry path. No combined benefit established. |

These are separate from the reviewer's generic/fused matcher experiments. No
compound variant, multiplied gain, or attribution from elapsed validation time
is claimed.

Both variants passed the same renewed control groups on CPU7:

- 34 dispatch/order observations covering selected-code reads, arity mutation,
  ordinary/registered/Proxy/custom method calls, partial/exact/overapplication,
  reentry and throws.
- 146 public ABI/prototype observations and 72 independent scalar observations.
- Nine exact-entry/environment/slot/reentry observations.
- 91 method/getter/raw-error/matcher observations and 121 independent scalar
  points, plus the unchanged original edit-distance result `2065873279` at
  `[2,0]` for both baseline and transformed modules.

The second intervention's method suite explicitly retains the expected private
permission difference `[[false],[true]]` for an accessor returning native `.call`.
The first intervention requires `[[false],[false]]`. Raw exception messages are
compared without normalization. Existing stable-intrinsic and private stack/source
introspection limits remain those in the prospective designs.

Raw evidence, relative to `selfhost/build/phase30/`:

| Evidence | Ordinary dispatch | Actual-method read |
|---|---|---|
| Checked helper + original module derivation | `inspection-inline-exact-14/derive.json` | `inspection-actual-method14/derive.json` |
| 34 dispatch traces | `inspection-inline-exact-dispatch14/report.json` | `inspection-actual-method-dispatch14/report.json` |
| 146 ABI +72 scalar | `inspection-inline-exact-abi14/report.json` | `inspection-actual-method-abi14/report.json` |
| Nine entry controls | `inspection-inline-exact-entry14/report.json` | `inspection-actual-method-entry14/report.json` |
| 91 method +121 points +original edit-distance | `inspection-inline-exact-method14/report.json` | `inspection-actual-method-method14/report.json` |
| Fresh checked14 owned-row derivation | `inspection-inline-exact-row14/derive.json` | `inspection-actual-method-row14/derive.json` |

Every acquisition/validation command has a separate immutable `-outer/run.json`
receipt and raw stdout/stderr. Both new row variants derive from
`runtime-row-source-14/candidate.mjs` and its adjacent checked receipt; the
independent Phase29 source is `runtime-row-source-29/candidate.mjs`. These are
fresh emissions of the same retained `prototype-owned-source-01/row.bend`, not
the older candidate13 row. The measurement owner is preparing identical complete
four-array adapters and the 28-point state oracle.

The row campaign is now complete. The independent full-state and alias/boundary
gates pass at `runtime-row-numeric-01/report.json`,
`runtime-row-boundaries-abc-01/report.json`, and
`runtime-row-boundaries-fused-01/report.json`. The clean maintained confirmation
is `runtime-row-confirm-01/report.json`; its separate short screen remains
`runtime-row-screen-01/report.json`. The [canonical campaign report](generic-runtime-row-diagnosis.md)
retains sample ranges, drift, complete receipts and the reviewer's original-matcher
reference distinctions.

| Same-window complete row32 variant | Median ms |
|---|---:|
| Phase29 | 0.450682 |
| Checked14 | 0.606265 |
| Inline ordinary exact dispatch | 0.610321 |
| Generic delayed matcher | 0.446850 |
| Fused registered matcher | 0.592224 |
| Actual-method authorization | 0.547576 |
| Pinned TypeScript | 0.008408 |

The selected generic matcher takes 26.29% less time than unchanged14 and overlaps
Phase29's sample range. Inlining ordinary dispatch gives no useful signal; fusing
the registered matcher gives only 2.32% less time. This supports attributing the
row regression to the registered selected-arm path as a whole, not to one precise
reflection, allocation or call instruction. The actual-method result independently
shows that its reflection policy contributes, but it does not establish a useful
increment after the selected matcher no longer uses that path.

Root selected only the generic delayed matcher for maintained attempt15. The
composition design/tool remains unexecuted. Renewed actual-compiler emission,
correctness and original-program transfer are still required; these generated-JS
row results do not lift the candidate14 release hold or establish whole-corpus
performance.
