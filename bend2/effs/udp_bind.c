// UDP
// ===

Term udp_bind_run(Env e, Term* f, IoWork* w) {
  int fd = socket(AF_INET, SOCK_DGRAM, 0);
  if (fd < 0) {
    return io_fail(e, (uint32_t)errno, NULL);
  }
  struct sockaddr_in at;
  if (io_sys_addr("0.0.0.0", (uint32_t)f[0], &at) < 0) {
    close(fd);
    return io_fail(e, EINVAL, NULL);
  }
  if (bind(fd, (struct sockaddr*)&at, sizeof(at)) < 0
    || fcntl(fd, F_SETFL, fcntl(fd, F_GETFL) | O_NONBLOCK) < 0) {
    uint32_t code = (uint32_t)errno;
    close(fd);
    return io_fail(e, code, NULL);
  }
  return io_done(e, io_hand(fd));
}

static void __attribute__((constructor)) udp_bind_use(void) {
  io_eff(CID_UDP_BIND, udp_bind_run, 0);
}
