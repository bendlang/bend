Term fd_append_run(Env e, Term* f, IoWork* w) {
  return io_hand(open("/tmp/bend_io_file_write_at_append_fd",
    O_WRONLY | O_APPEND));
}

Term ffi_keep_run(Env e, Term* f, IoWork* w) {
  return term_pak(CID(Unit), 0);
}

static void __attribute__((constructor)) fd_append_use(void) {
  io_eff(CID(Fd.append), fd_append_run);
  io_eff(CID(ffi_absent), ffi_keep_run);
  io_eff(CID(ffi_back), ffi_keep_run);
}
