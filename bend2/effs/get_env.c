// IO
// ==

uint32_t io_get_env(const char* name, const char** out) {
  const char* value = getenv(name);
  if (value == NULL) {
    return ENOENT;
  }
  *out = value;
  return 0;
}

Term io_get_env_run(Env e, Term* f, IoWork* w) {
  uint64_t n = 0;
  char* name = io_cstr(e, f[0], &n);
  const char* got = NULL;
  uint32_t q;
  if (io_nul(name, n)) {
    q = ENOENT;
  } else {
    q = io_get_env(name, &got);
  }
  free(name);
  if (q != 0) {
    return io_fail(e, q, NULL);
  }
  return io_done(e, io_str(e, got, strlen(got)));
}

static void __attribute__((constructor)) io_get_env_use(void) {
  io_eff(CID(IO.get_env), io_get_env_run, 0);
}
