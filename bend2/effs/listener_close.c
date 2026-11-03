// Listener
// ========

Term HID(listener_close_run)(Env e, Term* f, IoWork* w) {
  close((int)io_hand_v(f[0]));
  return term_pak(CID(Unit), 0);
}

static void __attribute__((constructor)) HID(listener_close_use)(void) {
  io_eff(CID(Listener.close), HID(listener_close_run));
}
