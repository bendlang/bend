// IO
// ==

void io_print(const char* data, uint64_t len) {
  io_out(stdout, data, len);
  io_out(stdout, "\n", 1);
}

Term io_print_run(Env e, Term* f, IoWork* w) {
  uint64_t n = 0;
  char* text = io_cstr(e, f[0], &n);
  io_print(text, n);
  free(text);
  return term_pak(CID_UNIT, 0);
}

static void __attribute__((constructor)) io_print_use(void) {
  io_eff(CID_IO_PRINT, io_print_run, 0);
}
