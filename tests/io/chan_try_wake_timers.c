// The native runtime cuts timers by other means: the clock keeps running.
Term clock_run(Env e, Term* f, IoWork* w) {
  return term_pak(CID(Unit), 0);
}

static void __attribute__((constructor)) clock_stop_use(void) {
  io_eff(CID(Clock.stop), clock_run);
  io_eff(CID(Clock.start), clock_run);
}
