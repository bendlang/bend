Term raw_two_run(Env e, Term* f, IoWork* w) {
  if (write(1, "two\n", 4)) {
  }
  return term_pak(CID(Unit), 0);
}

static void __attribute__((constructor)) raw_two_use(void) {
  io_eff(CID(raw_two), raw_two_run);
}
