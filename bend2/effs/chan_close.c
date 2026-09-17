// Chan
// ====

Term chan_close_run(Env e, Term* f, IoWork* w) {
  ChanRow* row = chan_at(f[0]);
  if (row != NULL && !row->shut) {
    chan_shut(e, row);
  }
  return term_pak(CID_UNIT, 0);
}

static void __attribute__((constructor)) chan_close_use(void) {
  io_eff(CID_CHAN_CLOSE, chan_close_run, 0);
}
