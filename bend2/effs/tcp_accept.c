// TCP
// ===

// TCP.accept's request is parked until the listener is readable; an accept
// that still finds no connection (the listener is non-blocking) parks
// again, or, for try_, until its deadline w->time, then answers Wait{}.
// The accepted socket is non-blocking for life.
static Term tcp_accept_more(Env e, IoWork* w) {
  int fd  = (int)w->hand;
  u64 at  = w->time;
  int got = accept(fd, NULL, NULL);
  if (got >= 0 && fcntl(got, F_SETFL, fcntl(got, F_GETFL) | O_NONBLOCK) < 0) {
    close(got);
    got = -1;
  }
  io_sys_end(w, got);
  if (w->code == EAGAIN && (at == 0 || io_tick() < at)) {
    return io_wait_on(w, fd, POLLIN, at, tcp_accept_more);
  }
  if (w->code == EAGAIN) {
    return io_tup(e, io_hand(fd), io_box(e, CID(Wait), term_pak(CID(Unit), 0)));
  }
  Term r = io_res(e, w, io_hand(got));
  return io_tup(e, io_hand(fd), at != 0 ? io_box(e, CID(Ready), r) : r);
}

#ifdef CID(TCP.accept)

Term tcp_accept_run(Env e, Term* f, IoWork* w) {
  w->hand = (intptr_t)io_hand_v(f[0]);
  w->time = 0;
  return tcp_accept_more(e, w);
}

static void __attribute__((constructor)) tcp_accept_use(void) {
  io_eff(CID(TCP.accept), tcp_accept_run, IO_READ);
}

#endif

#ifdef CID(TCP.try_accept)

Term tcp_try_accept_run(Env e, Term* f, IoWork* w) {
  w->hand = (intptr_t)io_hand_v(f[0]);
  w->time = io_tick() + (u64)f[1] * 1000000ull;
  return tcp_accept_more(e, w);
}

static void __attribute__((constructor)) tcp_try_accept_use(void) {
  io_eff(CID(TCP.try_accept), tcp_try_accept_run, 0);
}

#endif
