// File descriptors
// ================

static Term fd_close_run(Env e, Term* f, IoWork* w) {
  close((int)io_hand_v(f[0]));
  return term_pak(CID_UNIT, 0);
}

static void __attribute__((constructor)) fd_close_use(void) {
#ifdef CID_FILE_CLOSE
  io_eff(CID_FILE_CLOSE, fd_close_run, 0);
#endif
#ifdef CID_SOCKET_CLOSE
  io_eff(CID_SOCKET_CLOSE, fd_close_run, 0);
#endif
#ifdef CID_LISTENER_CLOSE
  io_eff(CID_LISTENER_CLOSE, fd_close_run, 0);
#endif
}
