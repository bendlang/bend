// File
// ====

Term file_close_run(Env e, Term* f, IoWork* w) {
  close((int)io_hand_v(f[0]));
  return term_pak(CID_UNIT, 0);
}

static void __attribute__((constructor)) file_close_use(void) {
  io_eff(CID_FILE_CLOSE, file_close_run, 0);
}
