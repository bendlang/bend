// UDP
// ===

Term udp_poll_run(Env e, Term* f, IoWork* w) {
  struct sockaddr_in at = { 0 };
  socklen_t alen = sizeof(at);
  char      host[16];
  int       fd   = (int)io_hand_v(f[0]);
  u32       max  = f[1] < INT32_MAX ? (u32)f[1] : INT32_MAX;
  char*     data = io_mem(malloc(max + 1));
  ssize_t   n    = recvfrom(fd, data, max, 0, (struct sockaddr*)&at, &alen);
  u32       code = n < 0 ? (u32)errno : 0;
  Term      r;
  if (code == EAGAIN) {
    r = io_done(e, term_pak(CID_NONE, 0));
  } else if (code != 0) {
    r = io_fail(e, code, NULL);
  } else {
    inet_ntop(AF_INET, &at.sin_addr, host, 16);
    r = io_done(e, io_box(e, CID_SOME, io_tup(e, io_str(e, host, strlen(host)),
      io_tup(e, ntohs(at.sin_port), io_str(e, data, (u64)n))), IO_HOTS & 32));
  }
  free(data);
  return io_tup(e, f[0], r);
}

static void __attribute__((constructor)) udp_poll_use(void) {
  io_eff(CID_UDP_POLL, udp_poll_run, 0);
}
