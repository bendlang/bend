# Retained selected execution evidence

`raw.tar.gz` preserves selected candidate03 JS/interpreter controls and their
live-reference counterparts, the original TCP permission failure and successful
elevated retry, all three foreign-runtime attempts, the generic-instantiation
falsifier and actual execution controls, and candidate06's full import capsule.
Frozen candidate03 and candidate06 APIs, bootstrap metadata, compiler sources
and host tools are included. The full frontend vectors and final release
promotion are separate evidence.

Archive SHA-256:
`979c49ea277715353669c4ceb5da0373c97990ea6e071a54669958ae8bf243cb`.
The archive contains 2,503 path identities, 1,685 distinct content objects and
6,315,169 compressed bytes. `archive.py` verifies every object's SHA-256 and
confirms that no original changed during the freeze; it refuses to overwrite
existing evidence.

`manifest.json` maps original repository-relative paths to content hashes. To
recover a file, extract `objects/<sha256>` and write those bytes to the intended
path. Absolute paths in raw reports remain exact; moving the checkout is not
claimed to be an exact replay. Node and the pinned upstream checkout remain
external prerequisites. The TCP controls require loopback permission.

Read [the report](../selected-js-execution.md) for the distinction between a
runtime-only candidate and a newly bootstrapped compiler, and between strict
fixture results and semantic acceptance/refusal counts. Failed attempts remain
present; the final passing controls do not replace their evidence.

The separate `release07.tar.gz` follow-up retains the final combined artifact's
44/44 actual execution gate and API/runtime/host identities. It has 233 path
identities, 187 objects and 852,682 compressed bytes; SHA-256
`edb92c370acecb8a4d5bec53f9ddc39679f74917b596530fc2d0f418b9fe02df`.
Use `release07-manifest.json` for recovery. `archive-release07.py` verified every
object and original. The initial archive and all prior failures are unchanged.
