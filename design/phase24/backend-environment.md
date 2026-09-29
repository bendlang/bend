# Phase24 backend environment investigation

This prospective plan covers a bounded environment-only investigation. It does
not change compiler source, generated runtime code, installed release artifacts,
upstream fixtures, or historical observations.

The Phase23 release has two JS TCP pairs whose candidate executions pass the
fixture oracle while the pinned TypeScript compiler's output requires `bun:ffi`
and cannot run under the recorded Node environment. The hypothesis is that a
locally pinned Bun can execute the unchanged emitted JS and close those exact
reference-environment gaps. Both programs must run under the same explicitly
recorded runtime policy; successful reference execution must match the complete
candidate result and unchanged fixture output. Historical failed pairs remain
failed. The backend owner will run the paired fixtures, using new Phase24 paths.

First inspect bounded existing executable locations and record their versions,
hashes, platform and resource settings. If no suitable Bun exists, inspect the
official pinned Bun 1.2.22 release and, within the disk bound, download its Linux
x64 binary into ignored `selfhost/build/phase24/backend-environment-01/`.
Keep the official release URL, download checksum/size and extracted executable
identity. Use no remote install script or global package installation. A failed
download, incompatible executable or rejected FFI access remains an environment
failure, not evidence about either compiler.

Separately inspect whether a Clang16-compatible ThreadSanitizer runtime exists
locally or has a small official distribution package. The earlier GCC10 runtime
did not provide Clang16's `__tsan_memcpy` and `__tsan_memset` calls. First require
a small independent pthread control to compile and run under the unmodified
toolchain, with a clean control and an intentional-race detection control. Only
then propose unchanged emitted-program sanitizer execution to the backend owner.
Do not remove instrumentation, rewrite `musttail`, suppress real reports, or
claim race freedom from sanitizer availability. Container mapping/security
failures should be retained as exact limitations rather than worked around.

The initial investigation lasts at most approximately 15 minutes, uses CPU7–8
only and adds at most 150 MB on disk. Check compressed plus extracted sizes before
downloading. Retain commands, stdout/stderr, exit status and actual identities in
new uniquely named directories. Pause expensive work if the root requests an
exclusive performance measurement. The outcome report is
`implementation/phase24/backend-environment.md`.

Preservation should add only the new environment/probe evidence and necessary
consumed helper versions. Reuse Phase23's immutable capsule and exact production
Git commit for unchanged compiler, fixtures and emitted programs. Bun/Clang are
explicit external toolchain prerequisites with pinned download recipes; do not
copy their binaries, all old attempt trees, or prior compressed archives into a
new evidence capsule. Record any genuine missing prerequisite explicitly. Review
the parent Phase24 capture plan for repeated payloads before publication.
