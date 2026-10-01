// UDP
// ===

// The request parks until the socket is readable, so a backlog never keeps
// the loop from its timers; a recv that still finds no datagram (the socket
// is non-blocking) parks again.
static Term udp_recv_from_more(Env e, IoWork* w) {
  struct sockaddr_in at = { 0 };
  socklen_t alen = sizeof(at);
  char      host[16];
  int       fd = (int)w->hand;
  u64       by = w->time;
  w->size = io_sys_end(w, recvfrom(fd, w->data, (size_t)w->made, 0,
    (struct sockaddr*)&at, &alen));
  if (w->code == EAGAIN && (by == 0 || io_tick() < by)) {
    return io_wait_on(w, fd, POLLIN, by, udp_recv_from_more);
  }
  Term r = io_box(e, CID(Wait), term_pak(CID(Unit), 0));
  if (w->code != EAGAIN) {
    inet_ntop(AF_INET, &at.sin_addr, host, 16);
    r = io_res(e, w, io_tup(e, io_str(e, host, strlen(host)),
      io_tup(e, ntohs(at.sin_port), io_str(e, w->data, w->size))));
    r = by != 0 ? io_box(e, CID(Ready), r) : r;
  }
  free(w->data);
  return io_tup(e, io_hand(w->hand), r);
}

// by is the try_ deadline (past it, Wait{}), 0 for the blocking twin.
static Term udp_recv_from_start(Env e, Term* f, IoWork* w, u64 by) {
  w->hand = (intptr_t)io_hand_v(f[0]);
  w->made = f[1] < INT32_MAX ? (intptr_t)f[1] : INT32_MAX;
  w->data = io_mem(malloc((size_t)w->made + 1));
  return io_wait_on(w, (int)w->hand, POLLIN, by, udp_recv_from_more);
}

#ifdef CID(UDP.recv_from)

Term udp_recv_from_run(Env e, Term* f, IoWork* w) {
  return udp_recv_from_start(e, f, w, 0);
}

static void __attribute__((constructor)) udp_recv_from_use(void) {
  io_eff(CID(UDP.recv_from), udp_recv_from_run);
}

#endif

#ifdef CID(UDP.try_recv_from)

Term udp_try_recv_from_run(Env e, Term* f, IoWork* w) {
  return udp_recv_from_start(e, f, w, io_tick() + (u64)f[2] * 1000000ull);
}

static void __attribute__((constructor)) udp_try_recv_from_use(void) {
  io_eff(CID(UDP.try_recv_from), udp_try_recv_from_run);
}

#endif
