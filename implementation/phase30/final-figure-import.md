# Final16 figures and compact metrics

The original prepared configuration is retained at
`selfhost/build/phase30/final-figure-plan-16/config.json`. The completed import
is [final16-figures/report.md](final16-figures/report.md), with all 13 copied
artifact hashes and visual-review notes in `final16-figures/import.json`.
It uses the separately retained16b plan to add the tree-bitonic follow-up and
explicit held/not-installed status. Visual review found overlapping scientific
notation labels; the retained16c display-only renderer shortens those labels
and adds two missing spaces. No data, aggregation or measurement changes.
Both provenance audits pass; the final PNGs were visually inspected before
byte-verified import. The16b artifacts remain available.

The imported report's held/native-pending status is frozen input metadata,
not a live release-status field. Native 81-observation recovery is now recorded
as exact, and P30-030 is selected for checked integration. The imported bytes
and hashes intentionally remain unchanged; use the parent release report for
subsequent integration and installation status. The broader 811-observation
backend set remains separate unexecuted work.
It selects checked16, its ten same-window original comparisons and four-point
scaling data. Held14's ten outcomes, the isolated runtime row and actual-image
small/long confirmations remain separate historical windows. The old 11→12
operation-count plot is explicitly historical; it is not relabeled final16.

The completed standalone SVG/PNG/CSV/JSON artifacts were generated after the
parent released the clean timing window with:

```sh
python3 selfhost/build/phase30/final-figure-plan-16c/render.py \
  selfhost/build/phase30/final-figure-plan-16c/config.json \
  selfhost/build/phase30/final-figures-16c
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

## Completed selected17 import

The original `final-figure-plan-17` remains unexecuted. Its fresh17b metadata
binding adds checked17's separate 15-second-warm tree-bitonic comparison to the
historical windows and uses the neutral status: “Measured selected17;
installation and CLI validation recorded separately in release-17.md”. The
renderer remains byte-identical to reviewed16c; no source timing or original
bar is changed, and no samples from different windows are pooled.

After the full17 matrix, long tree diagnostic and H17 comparison closed,
`final-figures-17b-outer` rendered successfully in 33.43 seconds. All three PNGs
were inspected: labels and legends are readable, original-program drift is
marked, scalar-helper scope is explicit, and historical11→12 counts retain
their non-CPU/non-final-image qualification. Thirteen generated files
(2447525 bytes) were imported byte-for-byte into
[`final17-figures`](final17-figures/report.md); its
[`import.json`](final17-figures/import.json) records every source/destination
hash and size plus visual review. The final16 and held14 imports remain intact.

The [checked17 timing report](final-timing-17.md) links the current diagrams and
retains the complete original table, request/process compiler costs, scaling
and separate long diagnostic. The imported report's neutral generation-time
status is immutable; actual installation and CLI checks are recorded in the
separate [release report](release-17.md).
