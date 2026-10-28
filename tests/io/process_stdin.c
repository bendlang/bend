static int stdin_saved = -1;

static Term stdin_seed(Env e, Term* f, IoWork* w) {
  stdin_saved = fcntl(0, F_DUPFD_CLOEXEC, 3);
  int fds[2];
  if (stdin_saved < 0 || pipe(fds) != 0) err_fail("stdin fixture setup failed");
  const char data[] = "one\ntwo\n";
  ssize_t n;
  do { n = write(fds[1], data, sizeof data - 1); } while (n < 0 && errno == EINTR);
  if (n != sizeof data - 1 || dup2(fds[0], 0) < 0) err_fail("stdin fixture write failed");
  close(fds[0]); close(fds[1]);
  return term_pak(CID(Unit), 0);
}

static Term stdin_close(Env e, Term* f, IoWork* w) {
  if (close(0) != 0) err_fail("stdin fixture close failed");
  return term_pak(CID(Unit), 0);
}

static Term stdin_restore(Env e, Term* f, IoWork* w) {
  if (dup2(stdin_saved, 0) < 0) err_fail("stdin fixture restore failed");
  close(stdin_saved); stdin_saved = -1;
  return term_pak(CID(Unit), 0);
}

static void __attribute__((constructor)) stdin_control_use(void) {
  io_eff(CID(Input.seed), stdin_seed);
  io_eff(CID(Input.close), stdin_close);
  io_eff(CID(Input.restore), stdin_restore);
}
