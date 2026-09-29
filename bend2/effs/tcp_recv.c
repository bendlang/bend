// TCP
// ===

// A recv that finds nothing (the socket is non-blocking) parks on more
// until the socket is readable. What it finds, read makes a String (io_str)
// or a List of bytes (io_list).
static Term tcp_recv_with(Env e, IoWork* w, IoPack more,
  Term (*read)(Env, const char*, u64)) {
  int fd  = (int)w->hand;
  w->size = io_sys_end(w, recv(fd, w->data, (size_t)w->made, 0));
  if (w->code == EAGAIN) {
    return io_wait_on(w, fd, POLLIN, 0, more);
  }
  Term r = io_res(e, w, read(e, w->data, w->size));
  free(w->data);
  return io_tup(e, io_hand(w->hand), r);
}

static Term tcp_recv_start(Env e, Term* f, IoWork* w, IoPack more) {
  w->hand = (intptr_t)io_hand_v(f[0]);
  if (f[1] == 0) {
    return io_tup(e, io_hand(w->hand), io_fail(e, EINVAL, NULL));
  }
  w->made = f[1] < INT32_MAX ? (intptr_t)f[1] : INT32_MAX;
  w->data = io_mem(malloc((size_t)w->made));
  return more(e, w);
}

#ifdef CID(TCP.recv)

static Term tcp_recv_more(Env e, IoWork* w) {
  return tcp_recv_with(e, w, tcp_recv_more, io_str);
}

Term tcp_recv_run(Env e, Term* f, IoWork* w) {
  return tcp_recv_start(e, f, w, tcp_recv_more);
}

static void __attribute__((constructor)) tcp_recv_use(void) {
  io_eff(CID(TCP.recv), tcp_recv_run, 0);
}

#endif

#ifdef CID(TCP.recv_bytes)

static Term tcp_recv_bytes_more(Env e, IoWork* w) {
  return tcp_recv_with(e, w, tcp_recv_bytes_more, io_list);
}

Term tcp_recv_bytes_run(Env e, Term* f, IoWork* w) {
  return tcp_recv_start(e, f, w, tcp_recv_bytes_more);
}

static void __attribute__((constructor)) tcp_recv_bytes_use(void) {
  io_eff(CID(TCP.recv_bytes), tcp_recv_bytes_run, 0);
}

#endif
