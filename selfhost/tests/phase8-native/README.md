# Phase 8 native compatibility controls

`run.mjs` exercises a frozen checked compiler API and its matching host/runtime
snapshot. It does not bootstrap the compiler. Set `BEND_PHASE8_PROJECT`,
`BEND_TYPED_API`, and `BEND_BASE` to that snapshot, then pass a new output directory.
Optional trailing names select individual fixtures. The process inherits CPU
pinning and the existing Clang `CC`, `CPATH`, `LIBRARY_PATH`, and `LD_LIBRARY_PATH`.
All child builds/executions run serially, with explicit timeouts and one native
worker. Raw source, tool inputs, generated C, program results, compiler details,
and input hashes remain in the output directory; a failed run is not overwritten.

The controls cover shared CID/FID scanning, namespace precedence, global fallback,
case-distinct constructor IDs, unchanged input values, text/Unicode preservation,
unknown names and a source imported into two namespaces. Positive fixtures are
actually checked, emitted to C, built, executed, and compared with their complete
expected stdout. The file-binary fixture includes byte range rejection, shared
input lists, offsets, EOF, and preserved file positions. Process controls include
UTF-8, argv boundaries, output limits, timeouts, failures, and parallel requests.
Channel tests exercise the retained runtime's rendezvous and close protocol.

The grouped native effects target the new pinned Base while retaining the old
native runtime representation. `chan.c` aggregates the historical wrappers;
copying upstream's new channel implementation would conflict with the runtime's
existing helpers and incompatible waiter queues. Other new/changed effects adapt
upstream `b2111cf43244e65f76ddc278ee695e669f720cbf` constructor spelling to `CID_*`.
The runtime only gains the audited `io_cbuf`/`io_list` byte conversions; the old
`io_cstr` operation becomes the string specialization of `io_cbuf`. In particular,
`tcp_poll.c` retains `io_wait_time(w)` because the new upstream `w->time` layout
is not part of this runtime.

Audio controls avoid opening a device; the Window control compiles the grouped
source and executes only its no-window branch. These controls do not establish
interactive display/audio behavior, macOS behavior, or CUDA/Metal compatibility.

The migrated Process C implementation requires the platform's close-from spawn
action (on Linux, `posix_spawn_file_actions_addclosefrom_np`). The actual pinned
upstream compiler and the migrated compiler both fail to build Process on this
host's glibc 2.31; `reference-process.mjs` preserves that comparison. No descriptor
closing fallback is substituted. The full upstream Process fixture also exceeds
the bounded compiler preparation budget, while the complete file-binary fixture
reaches C but exceeds the Clang budget. Those failures remain recorded; the smaller
`file_offsets` fixture tests the byte/offset boundary without claiming the full
file-binary gate passed.

The shared scanner explicitly receives both the full book (identifier lookup)
and the reachable effect scope (namespace ownership). `foreign-scope.mjs` records
the upstream/candidate comparison for two modules sharing a foreign source while
only one is reachable. The actual native and JavaScript `unused_namespace`
controls require success; the `duplicate` control calls both and requires
rejection. Physical symlink aliases still need host realpath-based foreign-source
canonicalization to match upstream completely.

Preserved migration gates: `native-controls-04` contains the initial port defects,
libc requirement and bounded timeouts; `native-controls-05` passes the corrected
Window/offset/duplicate slice; `native-controls-06` passes the final checked API's
13-control native/scanner capsule, including user `Clo.apply` returning `False{}`.
`native-foreign-scope-02`/`03` preserve the before/after namespace divergence.
