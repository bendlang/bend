// TCP
// ===

// The loop parked the request until the socket was readable; a recv that
// still finds nothing (the socket is non-blocking) parks again.
static Term tcp_recv_step(Env e, IoWork* w, Term (*more)(Env, IoWork*),
    Term (*pack)(Env, const char*, u64)) {
  int fd  = (int)w->hand;
  w->size = io_sys_end(w, recv(fd, w->data, (size_t)w->made, 0));
  if (w->code == EAGAIN) {
    return io_wait_on(w, fd, POLLIN, 0, more);
  }
  Term r = w->code ? io_fail(e, w->code, NULL)
    : io_done(e, pack(e, w->data, w->size));
  free(w->data);
  return io_tup(e, io_hand(w->hand), r);
}

static void tcp_recv_start(Term* f, IoWork* w) {
  w->hand = (intptr_t)io_hand_v(f[0]);
  w->made = f[1] < INT32_MAX ? (intptr_t)f[1] : INT32_MAX;
  w->data = io_mem(malloc((size_t)w->made + 1));
}

#ifdef CID(TCP.recv)

static Term tcp_recv_more(Env e, IoWork* w) {
  return tcp_recv_step(e, w, tcp_recv_more, io_str);
}

Term tcp_recv_run(Env e, Term* f, IoWork* w) {
  tcp_recv_start(f, w);
  return tcp_recv_more(e, w);
}

static void __attribute__((constructor)) tcp_recv_use(void) {
  io_eff(CID(TCP.recv), tcp_recv_run, IO_READ);
}

#endif

#ifdef CID(TCP.recv_bytes)

static Term tcp_recv_bytes_more(Env e, IoWork* w) {
  return tcp_recv_step(e, w, tcp_recv_bytes_more, io_list);
}

Term tcp_recv_bytes_run(Env e, Term* f, IoWork* w) {
  tcp_recv_start(f, w);
  return tcp_recv_bytes_more(e, w);
}

static void __attribute__((constructor)) tcp_recv_bytes_use(void) {
  io_eff(CID(TCP.recv_bytes), tcp_recv_bytes_run, IO_READ);
}

#endif
