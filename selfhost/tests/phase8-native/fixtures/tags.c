// CID/FID names resolve in this importing module before the global book.
_Static_assert(FID(answer) > 0, "the module's reachable function has an ID");
Term phase8_tags_run(Env e, Term* f, IoWork* w) {
  return term_pak(f[0] == 0 ? CID(Pick) : CID(pick), 0);
}
static void __attribute__((constructor)) phase8_tags_use(void) {
  io_eff(CID(get), phase8_tags_run, 0);
}
