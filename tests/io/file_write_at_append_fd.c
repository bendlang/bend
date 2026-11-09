Term fd_append_run(Env e, Term* f, IoWork* w) {
  uint64_t n = 0;
  char* path = io_cstr(e, f[0], &n);
  int fd = open(path, O_WRONLY | O_APPEND);
  free(path);
  return io_hand(fd);
}

Term ffi_keep_run(Env e, Term* f, IoWork* w) {
  return term_pak(CID(Unit), 0);
}

static void __attribute__((constructor)) fd_append_use(void) {
  io_eff(CID(Fd.append), fd_append_run);
  io_eff(CID(ffi_absent), ffi_keep_run);
  io_eff(CID(ffi_back), ffi_keep_run);
}
