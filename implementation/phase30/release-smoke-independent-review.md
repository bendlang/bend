# Independent review of the installed and relocated smoke test

The maintained Phase23 launcher and runner are suitable for the selected16
release without modification. This is a static review; the parent owns
installation and the42-step execution.

Invoke `history-release-smoke-launch.mjs` with the canonical selfhost project,
a fresh output directory and expected API
`33545640e25beffb61639b27f4815aaeb345fda14758e1d63418cd1d0ccc0637` after installing
and verifying attempt16. The current mixed development tree and installed29 API
must not be presented as a release16 smoke result. The install tool checks every
current compiler module, runtime and required host against the selected immutable
attempt and preserves the previous API/Base/lineage before replacing the release
manifest. It creates no new bootstrap compiler.

The launcher fixes CPU1, removes BEND_* and Node override variables, checks the
expected installed hash, applies the20-minute outer cap and requires exactly42
successful child observations without timeout, overflow, signal or input change.
The runner retains180-second child limits and4GiB Node heap allowances. It checks
ordinary and copied release verification, version, checking, interpretation,
JavaScript emission/execution and native build/execution on all three fixtures.
The expected target pin/version match final16.

Native compilation uses the same recorded Clang16 tree as the existing backend
receipts. `build/phase1/clang/root/usr/bin/clang-16` is the retained symlink to
`../lib/llvm-16/bin/clang`; the known binary SHA begins8a3f27cb. CPATH,
LIBRARY_PATH and LD_LIBRARY_PATH are set to that same tree explicitly. Relocated
compiler files intentionally continue to use this original external toolchain.
No upstream checkout is copied, but this is not filesystem isolation or a claim
of independence from a system/native toolchain.

Disk inspection during the backend acquisition found609MiB free. Historical
Phase24 smoke directories contain approximately7.5MiB each, including relocated
files and generated programs. The recorded installed release closure is roughly
3.1MiB before final16's small increase. A conservative50MiB reserve covers a new
release copy, API-specific Base caches, small C/JS/binary outputs, logs and the
previous release lineage; this is a practical estimate, not a hard allocation
bound. Recheck free space before installation if the final evidence archive has
consumed that reserve. No old evidence or source needs deletion for this smoke.

The existing runner's output/identity gates define its historical contract; this
review does not broaden them into full native conformance, arbitrary relocation
or empty-stderr assertions. Final installation and successful smoke receipts
remain separate from this static approval.

## Subsequent native acquisition finding

The later21-row native pilot renewal reports Clang16 `spawnSync ... EPERM` on
all17 positive native programs, identically for reference and candidate. Four
pre-build not-applicable cases still match. Thus the path/hash/environment is
correct, but the host-process observation is not yet suitable for validation.
The helper does not retain raw spawn status; compiled binaries in the fresh
archive make a pipe-capture EPERM-with-status0 plausible, rather than proving
that native process creation was denied.
This concrete runtime finding supersedes the static feasibility expectation:
release smoke's native build steps need a valid execution environment, potentially
an approved sandbox escalation. Do not label a matching EPERM as successful
native validation or infer that the42 steps have passed. No bypass or native
retry was performed by this review.

## Subsequent approved-environment recovery

The unchanged21-row native retry subsequently passed in the parent's explicitly
approved execution context: backend-pilot-recovered-16c/report.json restores the
full81-row pilot's exact historical observations (69 pass,8 NA,4 shared check
failures). The default repeat16b still failed with the same17 paired EPERM
observations. Minimal compile/run probes with both pipe and file capture passed
in both environments, so the larger runner's precise failure mechanism remains
unproven. The known toolchain and program outputs are validated by the approved
repeat; the default environment is not thereby repaired.

The42-step installed/relocated smoke still needs its own fresh receipt in a
working execution context. Its native steps cannot inherit pass status from the
pilot. Preserve the explicit outer approval/environment boundary if escalation
is used, keep the maintained runner and expected API unchanged, and retain any
default failure rather than silently changing its verdict.
