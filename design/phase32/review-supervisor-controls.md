# Independent supervisor negative controls

Prepared2026-09-30; no execution yet. Run only between root-owned acquisitions,
not nested inside bounded-run.py. The control orchestrator first probes the shared
exclusive lock; the unchanged supervisor then owns that lock throughout each
child. Both controls run serially. The current supervisor file is an exact input,
never edited or replaced by this test.

1. A small Python child explicitly touches160MiB under a128MiB process-tree RSS
   cap and a five-second deadline. Require stoppedFor=tree-rss-limit, child
   SIGKILL, supervisor exit1 and absence of the original child PID/start identity.
2. The same small child sleeps under a one-second deadline and128MiB RSS cap.
   Require stoppedFor=deadline, child SIGKILL, supervisor exit1 and child absence.

The child has an independent256MiB hard address-space limit and ten-second normal
lifetime. Unexpected normal completion exits42 and fails the control. The outer
control has a12-second timeout plus PID/start-identity-checked emergency cleanup,
which is recorded as a failure. No compiler, imports or benchmark runs are used.
The existing2GiB available-memory floor remains enabled. Reports retain the exact
consumed wrapper/child/controller identities, launch commands, resource receipts
and the post-exit PID observation.

These are expected negative acquisitions: the supervisor's complete=false and
exit1 are correct when its matching stop reason and cleanup are observed. The
outer test report passes only after both expected stops. This tests the two direct
child paths, not every descendant topology or a universal guarantee against OOM.
Polling can overshoot the RSS limit; the deliberately small independent ceiling
bounds this experiment while the receipt quantifies the observed overshoot.

Prepared commands:

```
python3 selfhost/tools/performance/phase32/review-supervisor-controls.py \
  selfhost/build/phase32/review-supervisor-controls-01
```
