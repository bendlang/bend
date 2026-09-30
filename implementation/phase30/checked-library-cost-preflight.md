# Checked-library compilation cost: prepared protocol

The prospective comparison is implemented but has not been executed. Its design
is `design/phase30/checked-library-compilation-cost.md`; the three tools are
`library-cost-plan.mjs`, `library-cost-worker.mjs` and `library-cost-run.mjs` in
`selfhost/tools/performance/phase30/`.

The plan is parameterized by the final checked attempt and its independently
saved transfer outputs. It preserves the original Mandelbrot/edit-distance
sources from transfer-12 and pairs pinned TypeScript with Phase29 attempt04 and
the selected final attempt. The worker performs the ordinary checked-library
API request, retains every output, and requires the corresponding previously
saved module hash. The runner rotates three fresh samples per side on exclusive
CPU0 and preserves request/import/process boundaries separately.

The analysis agent independently read the design, preparation, worker and
runner and found no static boundary or provenance blocker. In particular,
attempt verification does not preload bend.ts/comp.ts or the Bend API. Default
Bend lazy API loading stays inside its request, and each side's normal Base
handling remains included. Therefore request time and import-plus-request time
must both be reported; process wall also includes full provenance verification.

No measurement, syntax execution, plan acquisition or compiler run is claimed
by this preparation report. Configuration and execution await the parent's
exclusive timing release and final-attempt decision. Nothing invokes --verdict.
