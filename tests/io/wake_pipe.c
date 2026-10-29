// Check the actual pipe installed by io_loop, not a new pipe made by the test.
Term wake_check_run(Env e, Term* f, IoWork* w) {
  int flags = fcntl(io_wake_fd[0], F_GETFL);
  if (flags < 0 || !(flags & O_NONBLOCK)) {
    err_fail("wake pipe read end is not nonblocking");
  }
  return term_pak(CID(Unit), 0);
}

static void __attribute__((constructor)) wake_check_use(void) {
  io_eff(CID(Wake.check), wake_check_run);
}
