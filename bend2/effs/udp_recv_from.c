// UDP
// ===

// The loop parked the request until the socket was readable; a recv that
// still finds no datagram (the socket is non-blocking) parks again.
static Term udp_recv_from_more(Env e, IoWork* w) {
  struct sockaddr_in at = { 0 };
  socklen_t alen = sizeof(at);
  char      host[16];
  int       fd = (int)w->hand;
  w->size = io_sys_end(w, recvfrom(fd, w->data, (size_t)w->made, 0,
    (struct sockaddr*)&at, &alen));
  if (w->code == EAGAIN) {
    return io_wait_on(w, fd, POLLIN, udp_recv_from_more);
  }
  inet_ntop(AF_INET, &at.sin_addr, host, 16);
  Term r = w->code ? io_fail(e, w->code, NULL)
    : io_done(e, io_tup(e, io_str(e, host, strlen(host)),
      io_tup(e, ntohs(at.sin_port), io_str(e, w->data, w->size))));
  free(w->data);
  return io_tup(e, io_hand(w->hand), r);
}

Term udp_recv_from_run(Env e, Term* f, IoWork* w) {
  w->hand = (intptr_t)io_hand_v(f[0]);
  w->made = f[1] < INT32_MAX ? (intptr_t)f[1] : INT32_MAX;
  w->data = io_mem(malloc((size_t)w->made + 1));
  return udp_recv_from_more(e, w);
}

static void __attribute__((constructor)) udp_recv_from_use(void) {
  io_eff(CID_UDP_RECV_FROM, udp_recv_from_run, IO_READ);
}
