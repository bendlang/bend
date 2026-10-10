// IO
// ==

Term io_is_terminal_run(Env e, Term* f, IoWork* w) {
  return term_pak(isatty((int)(u32)f[0]) ? CID(True) : CID(False), 0);
}

static void __attribute__((constructor)) io_is_terminal_use(void) {
  io_eff(CID(IO.is_terminal), io_is_terminal_run);
}
