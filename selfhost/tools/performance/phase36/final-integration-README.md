# Phase36 inherited integration plan

This is a read/write planner. Root runs gates serially after selecting an actual
checked candidate and freezing normal performance admission separately.

```
python3 selfhost/tools/performance/phase36/final-integration-plan.py \
  selfhost/build/phase36/SELECTED_ATTEMPT selfhost/build/phase36/final-plan-NN \
  --added-module src/back/js/jpure.bend \
  --added-module src/back/js/fold.bend \
  --added-module src/back/js/producer.bend \
  --prepared selfhost/build/phase36/SELECTED_PREPARATION/manifest.json
```

Omit only the producer flag if that module was not admitted. The two Phase35
module flags remain explicit because the unchanged frontend migration assertion
starts from its Phase32 reference layout. All original module order and nonmodule
manifest fields remain checked. `producer.bend` is admitted only immediately after
`fold.bend`; no arbitrary module additions are permitted.

`final-integration-plan.json` records the exact derivation from the frozen Phase35
planner. The successor verifies its own and parent hashes before planning. It
reuses Phase35 tools directly, including the exact frontend/backend assertions,
all15 Phase35 owner groups and release/CLI gates. It records the already-known
scope/vector report-pointer corrections without changing any semantic assertion.
Phase35 files and closed evidence are never modified.

Use the existing runner and corrected audit:

```
python3 selfhost/tools/performance/phase35/final-integration-run.py PLAN \
  --stage preinstall --out NEW_LAUNCH
python3 selfhost/tools/performance/phase35/final-gate-audit-v2.py PLAN NEW_AUDIT \
  --owner-controls PLAN/owner/report.json --require-closed
```

The plan deliberately retains kind `phase35-final-integration-plan` for those
unchanged tools. `phase36-parentage.json` states its real ancestry and scope.
Phase36's actual-API producer, scoped-guard purity/refusal and compiler-cost
controls need a **separate owner closure audit**. They are not discharged by the
inherited15 groups. Normal compilation timings and full generated-program timings
also remain separate admission requirements. Installation runs only after all
these pass; the inherited postinstall stage and `--post-install` audit remain usable.

Final Phase36 owner requirements follow **retained changes**. The inliner
preflight experiment may be rejected if its normal compiler gain is below5%.
If rejected, record that decision and require no nonexistent
`j_region_inline_available` helper or synthetic preflight control on the final
API. Normal compiler-cost measurement still applies to the selected release.
Producer and scoped-guard owner checks are mandatory only if those changes are
retained; rejected proposals remain preserved evidence, not final API features.
