// TCP
// ===

// The request parks until the listener is readable, so a backlog never
// keeps the loop from its timers; an accept that still finds no connection
// (the listener is non-blocking) parks again. The accepted socket is
// non-blocking for life.
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
  return io_tup(e, io_hand(fd), io_res(e, w, io_hand(got)));
}

Term tcp_accept_run(Env e, Term* f, IoWork* w) {
  w->hand = (intptr_t)io_hand_v(f[0]);
  return io_wait_on(w, (int)w->hand, POLLIN, 0, tcp_accept_more);
}

static void __attribute__((constructor)) tcp_accept_use(void) {
  io_eff(CID(TCP.accept), tcp_accept_run);
}
