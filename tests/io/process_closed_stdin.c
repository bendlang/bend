Term shut_stdin_run(Env e, Term* f, IoWork* w) {
  if (close(0) != 0) abort();
  return term_pak(CID(Unit), 0);
}
static void __attribute__((constructor)) shut_stdin_use(void) {
  io_eff(CID(shut_stdin), shut_stdin_run);
}
