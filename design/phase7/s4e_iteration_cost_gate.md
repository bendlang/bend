# S4 E: final checked development-loop cost gate

Status: plan before measurement; no compiler change. The S4 bounded compiler is
installed and has passed its correctness, host/graph cost and relocation gates.
The overall design also guards the focused development loop. Existing S3/B02
run durations were collected under different concurrency and are not a controlled
comparison. Close this measurement gap before publishing the release checkpoint.

Use frozen S3 `baseline-project` and S4 `candidate-b02-project` source/tool trees
with the maintained equality-profile development workflow. Run four fresh attempts
serially on CPU 0 in A B B A order: identical pinned upstream, Node 24.18.0,
4 GiB heap, 4 MiB stack, one focused worker, and the same default 21-case selection.
Do not reuse compiled output or classify old run durations as new samples. Default
OS filesystem caches remain enabled for both; opposite order limits simple drift.
No intentional compiler job, archive compression or Git operation overlaps timing.

Measure complete launcher wall time including snapshotting, checked bootstrap,
derivation and focused validation; report build/validation phase durations as
context. A fresh Python worker waits for one compiler process tree and records Linux
`RUSAGE_CHILDREN.ru_maxrss` in KiB; full wall time is measured by the parent.
The first launcher attempt stopped before compilation because `/usr/bin/time`
is unavailable here. Its script and failed report remain preserved; the
corrected worker changes only measurement plumbing, not the compiler or gate. Require each paired
candidate/control full-loop ratio at most 1.05 and RSS ratio at most 1.10. Require
complete genuine checked attempts, passing focused validations with the same
seven known exact differences, expected checked/default API hashes and 55 exports.
Preserve all commands, configs, logs, attempts and measurements; a failure blocks
this checkpoint until diagnosed, not normalized away. Child deadline is three
minutes and the four-run experiment deadline is twelve minutes.

This is a measured development-loop comparison, not a full-source Bend-versus-
TypeScript compilation ratio or a new self-emitted compiler proof. Evidence is
separate under `selfhost/build/phase7/s4-loop/` because the original S4 raw capsule
has already been frozen and read back. Do not overwrite that capsule.
