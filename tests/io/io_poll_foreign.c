// A foreign effect written as guide/EFFECTS.md's "A pollable effect" says:
// its handle first, (handle, Result) back, and IO_IN declared.

static Term recv1_more(Env e, IoWork* w) {
  unsigned char b;
  ssize_t       n = recv((int)w->hand, &b, 1, 0);
  if (n < 0 && errno == EAGAIN) {
    return io_wait_on(w, (int)w->hand, POLLIN, 0, recv1_more);
  }
  io_sys_end(w, n);
  return io_tup(e, io_hand(w->hand), io_res(e, w, (Term)(n == 1 ? b : 256)));
}

Term recv1_run(Env e, Term* f, IoWork* w) {
  w->hand = (intptr_t)io_hand_v(f[0]);
  return recv1_more(e, w);
}

static void __attribute__((constructor)) recv1_use(void) {
  io_eff(CID(recv1), recv1_run, IO_IN);
}
