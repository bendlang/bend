// File
// ====

Term file_stdin_run(Env e, Term* f, IoWork* w) {
  int fd = fcntl(STDIN_FILENO, F_DUPFD_CLOEXEC, 3);
  io_sys_end(w, fd);
  return io_res(e, w, fd < 0 ? 0 : io_hand(fd));
}

static void __attribute__((constructor)) file_stdin_use(void) {
  io_eff(CID(File.stdin), file_stdin_run);
}
