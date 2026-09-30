# Independent resource-supervisor controls

Both planned negative controls passed in the root's serial acquisition. The
[exact report](supervisor-controls.json) retains commands, controller/child/wrapper
identities, expected stop reasons, resource receipts and post-exit observations.
The unchanged supervisor is SHA256
`860b59bce0b8c38e2e548368b14c51825bd62d8da1da200e2049737f1e0e383d`.

| Control | Required reason | Observed peak tree RSS | Wall time | Original child absent |
| --- | --- | ---: | ---: | --- |
| Touch160MiB under128MiB cap | tree-rss-limit |171.27MiB|0.105s|Yes|
| Sleep under one-second deadline | deadline |11.23MiB|1.011s|Yes|

Each supervisor returned1 with complete=false and child status SIGKILL, exactly
as required for an expected-stop test. The outer independent report passes only
because the correct reason and disappearance of the original PID/start identity
were both observed. Neither path needed the controller's emergency cleanup. The
child had an independent256MiB address-space ceiling and finite lifetime, so this
validation did not require a large allocation or compiler invocation.

The memory test also demonstrates polling overshoot: the128MiB RSS threshold is
an observed-stop threshold, not a kernel-enforced hard allocation ceiling. The
supervisor saw171.27MiB on its next sample before stopping the child. These controls
validate the direct-child RSS and deadline paths; they do not prove containment
of every descendant topology or diagnose the earlier session interruption.

Raw records are under `selfhost/build/phase32/supervisor-controls-01` and belong
in the final [Phase32 evidence capsule](evidence/README.md). The reviewer inspected
retained results without executing either control again.
