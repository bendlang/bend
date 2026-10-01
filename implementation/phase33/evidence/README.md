# Phase33 evidence

[validation.tar.gz](validation.tar.gz) preserves all closed files from
`selfhost/build/programs`, excluding Python bytecode caches. The
[manifest](manifest.json) records every member's hash, size and mode:
**3,085 files / 24,274,811 logical bytes**, compressed to **4,649,798 bytes**.
The archive was reopened and every member verified; all source files were then
rehashed to detect changes during capture.

Archive SHA256:
`754658d8d9f2904394f7023f5f5e511a591ae3e55619ee9fb1202c0759bf57a6`.
[The streaming capture script](preserve.py) is retained. Capture occurred after
all compiler, benchmark and control processes had closed, with no concurrent jobs.

Contents include:

- `validation-20`, `validation-60`, `validation-300`, `validation-600`: complete
  plans, same-run reports, raw samples, process logs, resource receipts, measured
  modules and consumed tool versions.
- Original installed/TypeScript/attempt acquisitions and the final hardened fast
  preparation, with all 42 checked source emissions and adapter receipts.
- `relocation-01`: the standalone copied suite and all 30 permission-restricted
  role/point checks, including the denied original-repository read witness.
- Unchanged/wrong-result prototype bundles and runs, and the intentionally
  incomplete `deadline-control-20` raytrace request.
- `controls`: command/result summaries, source/module and Base-path audits,
  prototype controls, and the relocation producer.

Synthetic unit-test fixtures were temporary and are not captured. Their commands,
exit results and test counts are summarized from the original tool outputs in
`controls/synthetic-controls.json`, including the initial sandbox child-spawn
EPERM and approved-context retry. The maintained test sources are committed.
Node binaries, pinned compiler checkouts and the historical checked compiler
attempt are identified, not duplicated in this capsule. Ordinary execution needs
only the committed portable reference and documented local prerequisites.

Extract to a new inspection directory:

```sh
mkdir /tmp/bend-phase33-evidence
tar -xzf implementation/phase33/evidence/validation.tar.gz -C /tmp/bend-phase33-evidence
```

Absolute paths inside receipts describe the acquisition machine. They are not
runtime dependencies of the [maintained reference](../../../selfhost/tools/performance/programs/README.md).
Use its documented commands for new experiments, with new output directories.
