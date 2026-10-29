// Makes io_sys() throw until ffi_back puts the FFI table back, as it does
// on every call on a host without bun:ffi, so the reads between them run
// as on node.
let ffi_real = undefined;

function ffi_absent_run() {
  ffi_real = io_sys();
  Object.defineProperty(globalThis, "BEND_SYS", {
    configurable: true,
    get() {
      throw new Error("no ffi table on this host");
    },
  });
  return { $: CID(Unit) };
}

function ffi_back_run() {
  Object.defineProperty(globalThis, "BEND_SYS", {
    configurable: true, enumerable: true, writable: true, value: ffi_real,
  });
  return { $: CID(Unit) };
}

io_eff(CID(ffi_absent), ffi_absent_run);
io_eff(CID(ffi_back), ffi_back_run);
