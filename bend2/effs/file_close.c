// File
// ====

#ifdef CID(File.read_line)
static int  file_line_sync(int fd);
static void file_line_drop(int fd);
#endif

// What File.read_line buffered goes back to a regular file first, so an
// fd shared past this handle (a child, a dup) reads on from the last line.
Term file_close_run(Env e, Term* f, IoWork* w) {
  int fd = (int)io_hand_v(f[0]);
#ifdef CID(File.read_line)
  file_line_sync(fd);
  file_line_drop(fd);
#endif
  close(fd);
  return term_pak(CID(Unit), 0);
}

static void __attribute__((constructor)) file_close_use(void) {
  io_eff(CID(File.close), file_close_run);
}
