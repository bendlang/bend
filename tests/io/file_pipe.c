Term pipe_open_run(Env e, Term* f, IoWork* w) {
  int fd[2];
  if (pipe(fd) < 0) return io_fail(e, errno, NULL);
  ssize_t n = write(fd[1], "abc", 3);
  int code = n < 0 ? errno : EIO;
  close(fd[1]);
  if (n != 3) {
    close(fd[0]);
    return io_fail(e, code, NULL);
  }
  return io_done(e, io_hand(fd[0]));
}

static void __attribute__((constructor)) pipe_open_use(void) {
  io_eff(CID_PIPE_OPEN, pipe_open_run, 0);
}
