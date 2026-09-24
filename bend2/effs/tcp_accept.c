// TCP
// ===

// The loop parked the request until the listener was readable; an accept
// that still finds no connection (the listener is non-blocking) parks
// again. The accepted socket is non-blocking for life.
static Term tcp_accept_more(Env e, IoWork* w) {
  int fd  = (int)w->hand;
  int got = accept(fd, NULL, NULL);
  if (got >= 0 && fcntl(got, F_SETFL, fcntl(got, F_GETFL) | O_NONBLOCK) < 0) {
    close(got);
    got = -1;
  }
  io_sys_end(w, got);
  if (w->code == EAGAIN) {
    return io_wait_on(w, fd, POLLIN, 0, tcp_accept_more);
  }
  Term r = w->code != 0 ? io_fail(e, w->code, NULL) : io_done(e, io_hand(got));
  return io_tup(e, io_hand(fd), r);
}

Term tcp_accept_run(Env e, Term* f, IoWork* w) {
  w->hand = (intptr_t)io_hand_v(f[0]);
  return tcp_accept_more(e, w);
}

static void __attribute__((constructor)) tcp_accept_use(void) {
  io_eff(CID(TCP.accept), tcp_accept_run, IO_READ);
}
