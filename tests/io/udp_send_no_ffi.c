// The native test uses the host's normal socket functions.
Term udp_no_ffi_arm_run(Env e, Term* f, IoWork* w) {
  return f[0];
}

static void __attribute__((constructor)) udp_no_ffi_arm_use(void) {
  io_eff(CID(UdpNoFfi.arm), udp_no_ffi_arm_run);
}
