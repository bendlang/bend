// IO
// ==

Term io_sleep_run(Env e, Term* f, IoWork* w) {
  return term_pak(CID(Unit), 0);
}

static void __attribute__((constructor)) io_sleep_use(void) {
  io_eff(CID(IO.sleep), io_sleep_run, IO_TIME);
}
