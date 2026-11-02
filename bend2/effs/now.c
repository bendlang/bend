// IO
// ==

Term HID(io_now_run)(Env e, Term* f, IoWork* w) {
  return (Term)(io_tick() / 1000000);
}

static void __attribute__((constructor)) HID(io_now_use)(void) {
  io_eff(CID(IO.now), HID(io_now_run));
}
