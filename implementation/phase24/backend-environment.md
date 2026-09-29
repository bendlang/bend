# Phase24 backend environment results

The two missing TCP execution oracles are now acquired: both unchanged upstream
programs under Bun match the unchanged self-hosted programs under Node24 exactly.
Matching Clang16 ThreadSanitizer support also works. Eight generated-program
executions pass their complete output oracles with no sanitizer diagnostics,
including a shared atomic witness on two distinct physical cores. No compiler,
runtime, emitted source, installed release or historical observation was edited.

The prospective [environment plan](../../design/phase24/backend-environment.md)
precedes acquisition. Follow-ups separately record the CPU-baseline Bun choice,
supported-host policy, generated-program sanitizer controls and two-core rerun.

## TCP oracle scope and retained failures

The official Bun1.2.22 default x64 executable exits with SIGILL even for
`--version`; this Ivy Bridge host has AVX but no AVX2. The official baseline build
runs and passes an independent `bun:ffi` libc/getpid smoke probe. The first ZIP
extractor also rejected the archive's harmless explicit directory entry before
extracting any file; that failed preparation remains recorded.

The first program attempt runs both sides under Bun. Both reference emissions
pass, but both candidate modules fail at import because Bun1.2.22 does not export
`node:util.getSystemErrorMap`. Those two nonexact observations remain in
`selfhost/build/phase24/backend-tcp-bun-01/report.json`; no generated import was
patched to conceal the runtime boundary.

The [supported-host plan](../../design/phase24/backend-environment-hosts.md)
then runs upstream emissions under Bun and candidate emissions under Node24,
with the original Node4MiB stack and4GiB heap flags. In
`selfhost/build/phase24/backend-tcp-supported-01/report.json`, both
`tcp_recv_max_zero` and `tcp_zero_idle` agree on complete stdout, empty stderr,
exit0 and no timeout. Their unchanged oracle is:

```text
poll: 22 Invalid argument
recv: 22 Invalid argument
recv_bytes: 22 Invalid argument
then recv 64: done: hello
```

All original fixtures, requests and saved JS bytes retain their hashes. These
are new execution observations on two explicitly different supported hosts.
They close the unavailable reference oracle for these programs; they do not
rewrite the old Node failures, establish candidate Bun compatibility, constitute
a new compilation, or support a performance comparison.

## Working sanitizer and actual generated programs

The installed compiler remains Clang16.0.6. Its missing compatible runtime is
supplied by official Debian package `libclang-rt-16-dev`, version
`1:16.0.6-15~deb11u2`. Only four x86_64 TSan archive/symbol-list members are
extracted into a new Phase24 directory. `-resource-dir` selects that runtime;
the unchanged existing Clang16 builtin include directory remains explicit.
No system package or old compiler installation is modified.

`backend-tsan-capability-01/report.json` records two independent pthread controls.
The atomic control prints20000 and exits0 without diagnostics. The intentional
non-atomic race exits66 and reports a ThreadSanitizer data race. Its external
symbolizer is unavailable, so the full raw binary-offset report is preserved.
This positive detection control distinguishes working instrumentation from merely
linking a sanitizer library.

| Preserved generated fixture | Configuration | Result |
| --- | --- | --- |
| `atomic_operations_v3` | Reference and candidate, two workers, CPU7 | 2/2 pass; all nine operations, overflow, index wrapping, CAS and F32 rounding. |
| `shared_array_ownership_v2` | Reference and candidate, two workers, CPU7 | 2/2 pass; shared boxed ownership, join/node reconstruction and clone alias result119. |
| `array_atomic_fadd` | Reference and candidate, two workers, CPU7 | 2/2 pass; sixteen logical branches share a buffer, output68 and2448.25. |
| Same unchanged `array_atomic_fadd` executables | Reference and candidate, two workers, CPUs2,3 | 2/2 pass; recorded package0/core2 and package0/core3 are distinct physical cores. |

The first two rows are in `backend-tsan-programs-01/report.json`, the third in
`backend-tsan-shared-01/report.json`, and the fourth in
`backend-tsan-parallel-01/report.json`, all under `selfhost/build/phase24/`.
Every compilation uses untouched Phase23 C, independently checked against its
durable capsule, with `-std=c11 -O1 -g -pthread -fsanitize=thread -fPIE -pie`.
Every execution has exact expected stdout, exit0, empty stderr and a30-second
deadline. Full flags, source/executable identities and compile/runtime messages
are retained. No instrumentation is suppressed.

These eight observations cover selected operation/ownership behavior and one
real shared atomic program. The all-operation fixture itself is sequential.
Two-core affinity provides a parallel execution configuration, not a scheduler
trace of every interleaving. There is no claim of universal race freedom,
arbitrary concurrent structural-read safety, GPU coverage or generated-code
speed. Historical Phase23 sanitizer linking failures keep their original status.

## Exact external prerequisites and reproduction

- [Official Bun1.2.22 release](https://github.com/oven-sh/bun/releases/tag/bun-v1.2.22):
  baseline asset `bun-linux-x64-baseline.zip`; the captured release API metadata,
  `SHASUMS256.txt` and download record bind its exact URL, bytes and checksum.
  Extracted Bun is103,661,840bytes, SHA256
  `c01b9916c9632dff543b8c99a0a9bdc043e263853f05b6ed91ac9060a2fc08d2`.
- [Official Debian runtime package](https://deb.debian.org/debian/pool/main/l/llvm-toolchain-16/libclang-rt-16-dev_16.0.6-15~deb11u2_amd64.deb):
  3,243,916bytes, SHA256
  `3316ea4250dc2e8aa083b8f865f6cb70473ceb395983619960f55680dc01b183`.
  This matches captured `apt-cache show` metadata. Package member paths and
  extracted hashes are recorded in the capability report.
- Node24.18.0 remains the original executable, SHA256
  `41a74efb34cbde5c7632cdac0cf8bd1a14d0b8d73dc1e82755014d9a9ce70f5c`.
  Clang, glibc2.31, headers/libraries and the Linux environment remain external
  prerequisites, with the unchanged Phase16 environment record bound by Phase23.

The reusable `selfhost/tools/performance/phase24/environment-*.py` scripts accept
a fresh evidence output path. They preserve raw failed outcomes and hashes.
The TSan capability script selectively extracts the exact package members and
records its explicit resource directory; subsequent program scripts reuse that
verified runtime. Restore the historical emitted programs from the existing
Phase23 capsule before replay. Existing attempt directories must not be reused.

## Storage and preservation review

The closed [environment evidence inventory](backend-environment-evidence.json)
enumerates only this task's seven fresh roots. Current logical bytes are
130,659,847, below the150MB initial bound. Only20,511,758bytes need new experiment
capture;110,148,089bytes are external Bun/Debian/runtime prerequisites with exact
download/extraction recipes. The failed default distribution and the successfully
unpacked baseline ZIP were removed only after identity checks, with explicit
disposal records. All failed command observations and official restoration
identities remain. No historical compiler evidence was removed.

The Phase24 parent design and backend campaign's350MiB local bound are reasonable
at the observed free space. Preserve new command/results, small controls, emitted
sanitizer executables and consumed script versions. Exclude the external binaries,
packages, extracted runtime libraries and reproducible Python cache from the
experiment capsule; reuse Phase23's capsule and exact Git inputs instead of
nesting old archives or copying its complete history. This report closes these
producers; it does not claim that the new Phase24 capsule is already archived
or independently recovered.
