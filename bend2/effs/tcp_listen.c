// TCP
// ===

uint32_t tcp_listen(uint32_t port, int* out) {
  int fd = socket(AF_INET, SOCK_STREAM, 0);
  if (fd < 0) {
    return (uint32_t)errno;
  }
  int one = 1;
  setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &one, sizeof(one));
  struct sockaddr_in at;
  if (io_sys_addr("0.0.0.0", port, &at) < 0) {
    close(fd);
    return EINVAL;
  }
  int bound = bind(fd, (struct sockaddr*)&at, sizeof(at));
  if (bound < 0 || listen(fd, 16) < 0
    || fcntl(fd, F_SETFL, fcntl(fd, F_GETFL) | O_NONBLOCK) < 0) {
    uint32_t code = (uint32_t)errno;
    close(fd);
    return code;
  }
  *out = fd;
  return 0;
}

Term tcp_listen_run(Env e, Term* f, IoWork* w) {
  int out;
  uint32_t q = tcp_listen((uint32_t)f[0], &out);
  if (q != 0) {
    return io_fail(e, q, NULL);
  }
  return io_done(e, io_hand(out));
}

static void __attribute__((constructor)) tcp_listen_use(void) {
  io_eff(CID_TCP_LISTEN, tcp_listen_run, 0);
}
