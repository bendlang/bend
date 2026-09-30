# JavaScript primitive runtime

Edit the fragments here, then run `node src/runtime/js/build.mjs` to regenerate
`src/runtime.mjs`, which is embedded in standalone generated programs.

- `core.mjs`: values, application trampoline, constructor operations.
- `base.mjs`: optimized numeric and collection operations and compatibility ABI.
- `effects.mjs`: files, channels, scheduling, TCP/UDP, clocks, entropy, environment,
  headless windows, and the upstream-compatible silent audio queue.
- `readback.mjs`: typed output and entry-point error handling.
- `foreign.mjs`: compiler-described foreign layout conversion and module calls.

These modules implement runtime operations only. The parser, normalizer,
checker, specialization and code emitter are written in Bend2.

`node src/runtime/js/test.mjs` checks numeric boundaries, readback, binary files,
channel rendezvous and local TCP/UDP exchanges. Foreign modules and deep values
are checked by `src/back/js/test-foreign.mjs`.

The JavaScript lane executes on one host thread. Window.open reports the same
headless failure as upstream JavaScript; Audio uses its timed silent queue.

The emitter's internal `callOwned` consumes a fresh non-tail argument vector.
Public `call`, matcher vectors and tail messages retain copying; bound prefixes
and oversaturation retain their existing isolation. Only compiler-created array
literals qualify. See the [Phase30 ownership report](../../../../implementation/phase30/owned-arguments.md).
