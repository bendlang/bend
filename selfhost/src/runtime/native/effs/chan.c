// Grouped channel effects for the retained IoQue/IoAct runtime.
// The old separate source files remain available for historical artifacts.

#ifdef CID_CHAN_NEW
// Chan
// ====

Term chan_new_run(Env e, Term* f, IoWork* w) {
  return chan_open((u32)f[0]);
}

static void __attribute__((constructor)) chan_new_use(void) {
  io_eff(CID_CHAN_NEW, chan_new_run, 0);
}

#endif

#ifdef CID_CHAN_SEND
// Chan
// ====

Term chan_send_run(Env e, Term* f, IoWork* w) {
  ChanRow* row = chan_at(f[0]);
  if (row == NULL || row->shut) {
    term_drop(e, f[1]);
    return chan_bool(false);
  }
  if (row->wait.head != NULL && row->wait.head->item == TERM_HOLE) {
    chan_wake(row, chan_some(e, f[1]));
    return chan_bool(true);
  }
  if (row->size < row->room) {
    row->ring[(row->head + row->size) % row->room] = f[1];
    row->size += 1;
    return chan_bool(true);
  }
  return chan_park(row, w, f[1]);
}

static void __attribute__((constructor)) chan_send_use(void) {
  io_eff(CID_CHAN_SEND, chan_send_run, 0);
}

#endif

#ifdef CID_CHAN_RECV
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

#endif

#ifdef CID_CHAN_CLOSE
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

#endif
