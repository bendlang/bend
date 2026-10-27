// bend-ids 1
// CID #Unit BEND_CID_Unit
// CID :Clock.stop BEND_CID_Clock_stop
// bend-ids end
// The native runtime cuts timers by other means: the clock keeps running.
Term clock_stop_run(Env e, Term* f, IoWork* w) {
  return term_pak(BEND_CID_Unit, 0);
}

static void __attribute__((constructor)) clock_stop_use(void) {
  io_eff(BEND_CID_Clock_stop, clock_stop_run);
}
