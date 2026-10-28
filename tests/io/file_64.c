static Term file_64_new(Env e, Term* f, IoWork* w) {
  const char* dir = getenv("TMPDIR");
  char name[4096];
  int n = snprintf(name, sizeof name, "%s/bend-file64-XXXXXX", dir ? dir : "/tmp");
  if (n < 0 || (size_t)n >= sizeof name) err_fail("temporary file path too long");
  int fd = mkstemp(name);
  if (fd < 0) err_fail("could not create temporary file");
  if (unlink(name) != 0) { close(fd); err_fail("could not unlink temporary file"); }
  return io_hand(fd);
}
static void __attribute__((constructor)) file_64_use(void) {
  io_eff(CID(Host.file), file_64_new);
}
