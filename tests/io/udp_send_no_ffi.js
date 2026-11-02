// Fail one FFI access. io_fail catches it after address validation.
function udp_no_ffi_arm(socket) {
  const prior = Object.getOwnPropertyDescriptor(globalThis, "BEND_SYS");
  Object.defineProperty(globalThis, "BEND_SYS", {
    configurable: true,
    get() {
      if (prior) {
        Object.defineProperty(globalThis, "BEND_SYS", prior);
      } else {
        delete globalThis.BEND_SYS;
      }
      throw new Error("no ffi on this host");
    },
  });
  return socket;
}

io_eff(CID(UdpNoFfi.arm), udp_no_ffi_arm);
