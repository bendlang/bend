// IO
// ==

Term io_sleep_run(Env e, Term* f, IoWork* w) {
  return term_pak(CID_UNIT, 0);
}

static void __attribute__((constructor)) io_sleep_use(void) {
  io_eff(CID_IO_SLEEP, io_sleep_run, IO_TIME);
}
