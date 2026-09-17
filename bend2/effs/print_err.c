// IO
// ==

Term io_print_err_run(Env e, Term* f, IoWork* w) {
  io_errs(e, f[0]);
  return term_pak(CID_UNIT, 0);
}

static void __attribute__((constructor)) io_print_err_use(void) {
  io_eff(CID_IO_PRINT_ERR, io_print_err_run, 0);
}
