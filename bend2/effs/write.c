// IO
// ==

Term io_write_run(Env e, Term* f, IoWork* w) {
  uint64_t n = 0;
  char* text = io_cstr(e, f[0], &n);
  io_out(stdout, text, n);
  free(text);
  return term_pak(CID_UNIT, 0);
}

static void __attribute__((constructor)) io_write_use(void) {
  io_eff(CID_IO_WRITE, io_write_run, 0);
}
