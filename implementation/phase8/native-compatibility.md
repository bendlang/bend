# Phase 8 native compatibility report

Target: upstream b2111cf43244e65f76ddc278ee695e669f720cbf. The port retains the
existing native runtime and representation. It does not import upstream's whole
runtime or claim a self-hosting fixed point. Actual gates below use checked B1
candidate snapshots and their matching frozen host/native assets.

## Changes

- New grouped `chan.c` reuses the old four wrappers. The retained runtime has
  `IoQue` waiters and `IoAct` activations; copying upstream's grouped channel
  implementation would duplicate helpers and use incompatible waiter layouts.
  Existing separate effect files are preserved.
- Added/adapted upstream `audio.c`, `window.c`, `process_run.c`, `thread_count.c`;
  constructor identifiers use the retained `CID_*` ABI. Window additionally
  threads `Env` through its new square renderer because retained `term_peek`
  takes `Env`, not the new upstream raw corpus pointer.
- Updated only the effects required by new Base contracts: File.read_bytes,
  File.read_at, File.write_bytes, TCP.recv_bytes/TCP.send_bytes, and the new
  host+port TCP.listen/UDP.bind signatures.
- Runtime changes are bounded to generalized `io_cbuf` (string UTF-8 or checked
  bytes), its `io_cstr` specialization, and `io_list`. Queue, scheduler, heap,
  execution, and GPU representations remain unchanged. Old tcp_poll retains
  `io_wait_time(w)`; upstream's new `w->time` field is not in this runtime.
- Shared `kf_source` resolves CID/FID in importing namespace before global
  names. It preserves literal text, ASCII token boundaries, and Unicode text;
  accumulators are reversed to avoid quadratic character appends. Backend
  rendering remains separate. Native user constructors keep injective encoded
  identities; legacy scoped CID_* aliases remain available. Unknown names and
  one exact foreign path imported from two namespaces are rejected.

## Preserved evidence

- `selfhost/build/phase8/native-controls-01`: 3/4 controls pass; thread_count
  checked/emitted but Clang absent from PATH. This was environment setup.
- `selfhost/build/phase8/native-controls-02`: 3/4; correct Clang found but its
  spawn was denied EPERM by sandbox. No C semantic result.
- `selfhost/build/phase8/native-controls-03`: 4/4; actual checked C/Clang16 CPU
  thread_count execution passes, along with scanner and input controls.
- `selfhost/build/phase8/native-controls-04`: candidate03, 19/24 controls pass.
  Fifteen positive programs actually compile and execute with exact stdout:
  thread_count; chan_rendezvous/chan_close_send/chan_pipe; read_bytes;
  tcp_bytes/tcp_listen_close; udp_bad_address; audio_only_open/write/close;
  marshal_imported_nullary; foreign_arrow_arity; foreign_types; namespaced
  CID/FID with case-distinct constructors. Unknown-ID rejection passes, as do
  two direct scanner controls and source immutability.

The five failures in 04 remain visible:

1. Full Process.run exceeded the 90-second compiler-preparation cap before C.
2. Process.run_parallel emitted C, but this host's glibc 2.31 lacks
   `posix_spawn_file_actions_addclosefrom_np`.
3. Full file_binary emitted approximately 1.84 MB of C but exceeded the
   20-second Clang build cap. This is not counted as semantic success.
4. Window's initial raw-corpus call into old `term_peek(Env, Term)` failed C
   typing; the owned local port was corrected to pass Env explicitly.
5. Initial duplicate-namespace fixture incorrectly assumed two aliases of one
   module create two namespaces. The loader correctly canonicalizes that one
   module. The corrected fixture has two distinct modules sharing one C file.

`selfhost/build/phase8/native-process-reference-01/report.json` records the actual
new pinned TypeScript compiler checking and emitting Process.run_parallel, then
building with the same Clang/libc. It fails on the identical missing spawn
operation. This establishes an environment requirement shared with upstream.
No unsafe descriptor snapshot/fallback or declaration-only workaround was used.

## Limits

CPU Linux only. Audio tests avoid a real audio device; Window's test uses its
no-window branch. No display, macOS, CUDA, or Metal behavior is established.
The source namespace guard currently compares normalized book paths; physical
symlink aliases of foreign sources need host canonicalization to match
upstream's realpath-based deduplication fully. The full Process/file-binary
performance caps remain failures; small controls must not be reported as those
full gates passing.

Follow-up candidate04 controls pending: corrected Window, smaller byte-offset
write/read slice, and corrected duplicate-namespace rejection. Their result will
be handed off separately when the integrated checked API is available.

Additional read-only review caveat (not an executed fixture): `kf_namespaces`
examines the full supplied book, while upstream chooses namespaces only from
reachable emitted foreign definitions. A file shared by two module namespaces
with only one reachable effect may therefore be rejected too early. The two
concepts should be separated: reachable effect scope selects namespace; full
semantic context resolves CID/FID names. Current duplicate control deliberately
makes both namespaces reachable, so it does not test this distinction.

## Follow-up evidence and final owned status

`native-controls-05` uses genuine checked candidate05 and passes 6/6 controls:
Window's explicit Env adaptation builds and runs the no-window branch; the small
file-offset program writes bytes 0/128/255/10, reads at offset one, then confirms
the sequential cursor remains at zero; the corrected two-module shared-source
fixture rejects. Direct scanner/input controls also pass.

The reachable-scope caveat was confirmed, then fixed. The preserved comparison
`native-foreign-scope-02` uses the final C+JS companion fixture set: upstream emits
native C successfully; candidate05 rejects the unused second module's namespace.
The fix separates full identifier-resolution context from emitted-effect scope.
There are no new compatibility wrappers: kf_source takes full book + scope;
nc_foreign_source renders the already parsed result; nc_foreign_scope uses the
same nc_live_names closure as native path gathering. The host passes its pruned
JS emission book as scope and computes native scope once. All maintained callers
migrated, and historical frozen snapshots remain unchanged.

`native-foreign-scope-03` uses the same final fixture inputs and checked
candidate06; upstream and candidate both emit successfully. `native-controls-06`
passes 13/13 controls on the same genuine artifact: seven native programs really
build/execute (thread_count, chan_rendezvous, namespaced constructor case/FID,
Window guarded, byte offsets, unused namespace, user Clo.apply); the unused
namespace program also executes emitted JS; unknown/reachable-duplicate guards,
direct scanner controls and unchanged-input checks pass. User Clo.apply returns
exactly False{}. Root additionally renamed the runtime's internal FID_CLO_APPLY
macro to BEND_CLO_APPLY so it cannot collide with nt_fid's user-function namespace;
that is separate from the bounded effect/byte helper port described above.

CPU slots are released and no owned CPU jobs remain. The physical symlink alias
limitation, old-libc Process requirement and full-fixture timeouts remain explicit.
No GPU/display/audio-device validation or whole-suite success is claimed.
