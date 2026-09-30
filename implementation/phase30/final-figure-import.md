# Final16 figures and compact metrics

The configuration is frozen at
`selfhost/build/phase30/final-figure-plan-16/config.json`. No plot has been run.
It selects checked16, its ten same-window original comparisons and four-point
scaling data. Held14's ten outcomes, the isolated runtime row and actual-image
small/long confirmations remain separate historical windows. The old 11→12
operation-count plot is explicitly historical; it is not relabeled final16.

After all measurements complete and the parent releases the clean timing
window, generate the standalone SVG/PNG/CSV/JSON artifacts with:

```sh
python3 selfhost/tools/performance/phase30/inspect-final-figures.py \
  selfhost/build/phase30/final-figure-plan-16/config.json \
  selfhost/build/phase30/final-figures-16
```

Use an outer acquisition receipt if launching through `run.py`. The plotting
tool validates source, image, module, report and raw sample identities before
rendering. It recomputes all medians, ratios, sample-extrema envelopes and drift
markers; it fails if a report or checked-image receipt does not match. Its
candidate-status text intentionally leaves installation to the release record.

Import into a fresh `implementation/phase30/final16-figures/` directory only
after `generation.json` reports `complete: true` and `pass: true`. Copy each
top-level file from the generated directory, including consumed tool/config,
generation receipt, Markdown report, CSV/JSON summaries and SVG/PNG files. Do
not copy the matplotlib cache. Verify byte hashes after copying and write an
`import.json` recording source directory, release-status scope and every copied
filename/hash/size, as was done for `held14-figures`. Preserve the held14 import.
Link the new generated report and two final-image plots from the phase report;
keep the historical mechanism plot's original 11→12 label.

The short final metrics table should separate scopes, for example:

| Metric | Checked16 result | Reference / scope |
| --- | --- | --- |
| Original Mandelbrot | Median ms; ratio to Phase29 and TS | Same-window original point; separate long-warmup check |
| Remaining original programs | Individual ratios or linked ten-row table | No pooled production-workload average |
| Compiler ordinary check | Median request and process ms | Same frozen compiler source; costs kept separate |
| Checked library generation | Two request medians | Same original Mandelbrot/edit-distance source |
| Frontend conformance | Exact renewed outcome counts | Main 3026 and broader 196 observations; distinguish shared failures |
| JS backend conformance | Targeted/broad exact outcome counts | Separately recorded 81/811 sets and residual differences |
| H backend | Actual retained gate status | Bounded acquisition/execution; do not infer unmeasured equivalence |
| Production complexity | Physical/nonblank lines, definitions, types/modules | Frozen checked16 source; reports/tools excluded |

Only populate pending fields from final raw reports and the selected image's
metrics. Ratios from different windows must not be multiplied into one claimed
gain. Sample minima/maxima are not confidence intervals, and marked warmup drift
must remain visible in the final figures and prose.

Readiness audit `final-batch-readiness-16.json` rechecked all 751 batch input
identities with no mismatch or preexisting output directory. The comparable
held14 job outputs occupy about 15.1 MiB on disk in total; reserving 30–40 MiB for
the renewed matrix, separate long comparison and figure/import artifacts is
conservative for these same protocols. This excludes additional H/conformance
artifacts and final raw-evidence archiving. The observed free space was
623832 KiB (about 609 MiB); no files were deleted for this estimate.
