// An unlinked sparse fixture, seeded independently of File.write_bytes.
Term sparse_open_run(Env e, Term* f, IoWork* w) {
  char path[] = "/tmp/bend_io_sparse_XXXXXX";
  int fd = mkstemp(path);
  if (fd < 0) return io_fail(e, errno, NULL);
  unlink(path);
  uint8_t bytes[] = {128, 0, 255};
  ssize_t n = pwrite(fd, bytes, sizeof bytes, (off_t)4294967303ull);
  if (n != sizeof bytes) {
    int code = n < 0 ? errno : EIO;
    close(fd);
    return io_fail(e, code, NULL);
  }
  return io_done(e, io_hand(fd));
}

static void __attribute__((constructor)) sparse_open_use(void) {
  io_eff(CID_SPARSE_OPEN, sparse_open_run, 0);
}
