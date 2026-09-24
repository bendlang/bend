// TCP
// ===

static Term tcp_recv_pack(Env e, IoWork* w) {
  Term r = w->code ? io_fail(e, w->code, NULL)
    : io_done(e, io_str(e, w->data, w->size));
  free(w->data);
  return io_tup(e, io_hand(w->hand), r);
}

// The loop parked the request until the socket was readable; a recv that
// still finds nothing (the socket is non-blocking) parks again.
static Term tcp_recv_more(Env e, IoWork* w) {
  int fd  = (int)w->hand;
  w->size = io_sys_end(w, recv(fd, w->data, (size_t)w->made, 0));
  return w->code == EAGAIN ? io_wait_on(w, fd, POLLIN, 0, tcp_recv_more)
    : tcp_recv_pack(e, w);
}

Term tcp_recv_run(Env e, Term* f, IoWork* w) {
  w->hand = (intptr_t)io_hand_v(f[0]);
  w->made = f[1] < INT32_MAX ? (intptr_t)f[1] : INT32_MAX;
  w->data = io_mem(malloc((size_t)w->made + 1));
  return tcp_recv_more(e, w);
}

static void __attribute__((constructor)) tcp_recv_use(void) {
  io_eff(CID(TCP.recv), tcp_recv_run, IO_READ);
}
