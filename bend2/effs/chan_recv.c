// Chan
// ====

Term chan_recv_run(Env e, Term* f, IoWork* w) {
  ChanRow* row = chan_at(f[0]);
  if (row == NULL) {
    return term_pak(CID_NONE, 0);
  }
  if (row->size > 0) {
    Term v = chan_take(row);
    if (row->shut && row->size == 0) {
      chan_free(row);
    }
    return chan_some(e, v);
  }
  if (row->wait.head != NULL && row->wait.head->item != TERM_HOLE) {
    return chan_some(e, chan_wake(row, chan_bool(true)));
  }
  if (row->shut) {
    chan_free(row);
    return term_pak(CID_NONE, 0);
  }
  return chan_park(row, w, TERM_HOLE);
}

static void __attribute__((constructor)) chan_recv_use(void) {
  io_eff(CID_CHAN_RECV, chan_recv_run, 0);
}
