// TCP
// ===

// A recv that finds nothing (the socket is non-blocking) parks on more
// until the socket is readable, or, for try_, until its deadline w->time,
// then answers Wait{}. What it finds, read makes a String (io_str) or a
// List of bytes (io_list): Some{data}, or None{} at the peer's end.
static Term tcp_recv_with(Env e, IoWork* w, IoPack more,
  Term (*read)(Env, const char*, u64)) {
  int fd  = (int)w->hand;
  u64 at  = w->time;
  w->size = io_sys_end(w, recv(fd, w->data, (size_t)w->made, 0));
  if (w->code == EAGAIN && (at == 0 || io_tick() < at)) {
    return io_wait_on(w, fd, POLLIN, at, more);
  }
  Term r = w->code == EAGAIN ? io_box(e, CID(Wait), term_pak(CID(Unit), 0))
    : io_res(e, w, w->size == 0 ? term_pak(CID(None), 0)
      : io_box(e, CID(Some), read(e, w->data, w->size)));
  if (at != 0 && w->code != EAGAIN) {
    r = io_box(e, CID(Ready), r);
  }
  free(w->data);
  return io_tup(e, io_hand(w->hand), r);
}

// at is the try_ deadline, 0 for the blocking twins.
static Term tcp_recv_start(Env e, Term* f, IoWork* w, IoPack more, u64 at) {
  w->hand = (intptr_t)io_hand_v(f[0]);
  w->time = at;
  if (f[1] == 0) {
    Term r = io_fail(e, EINVAL, NULL);
    return io_tup(e, io_hand(w->hand), w->time ? io_box(e, CID(Ready), r) : r);
  }
  w->made = f[1] < INT32_MAX ? (intptr_t)f[1] : INT32_MAX;
  w->data = io_mem(malloc((size_t)w->made));
  return more(e, w);
}

static Term tcp_recv_more(Env e, IoWork* w) {
  return tcp_recv_with(e, w, tcp_recv_more, io_str);
}

#ifdef CID(Con)

static Term tcp_recv_bytes_more(Env e, IoWork* w) {
  return tcp_recv_with(e, w, tcp_recv_bytes_more, io_list);
}

#endif

#ifdef CID(TCP.recv)

Term tcp_recv_run(Env e, Term* f, IoWork* w) {
  return tcp_recv_start(e, f, w, tcp_recv_more, 0);
}

static void __attribute__((constructor)) tcp_recv_use(void) {
  io_eff(CID(TCP.recv), tcp_recv_run, 0);
}

#endif

#ifdef CID(TCP.recv_bytes)

Term tcp_recv_bytes_run(Env e, Term* f, IoWork* w) {
  return tcp_recv_start(e, f, w, tcp_recv_bytes_more, 0);
}

static void __attribute__((constructor)) tcp_recv_bytes_use(void) {
  io_eff(CID(TCP.recv_bytes), tcp_recv_bytes_run, 0);
}

#endif

#ifdef CID(TCP.try_recv)

Term tcp_try_recv_run(Env e, Term* f, IoWork* w) {
  return tcp_recv_start(e, f, w, tcp_recv_more,
    io_tick() + (u64)f[2] * 1000000ull);
}

static void __attribute__((constructor)) tcp_try_recv_use(void) {
  io_eff(CID(TCP.try_recv), tcp_try_recv_run, 0);
}

#endif

#ifdef CID(TCP.try_recv_bytes)

Term tcp_try_recv_bytes_run(Env e, Term* f, IoWork* w) {
  return tcp_recv_start(e, f, w, tcp_recv_bytes_more,
    io_tick() + (u64)f[2] * 1000000ull);
}

static void __attribute__((constructor)) tcp_try_recv_bytes_use(void) {
  io_eff(CID(TCP.try_recv_bytes), tcp_try_recv_bytes_run, 0);
}

#endif
