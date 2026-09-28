Term phase8_unknown_run(Env e, Term* f, IoWork* w) { return CID(NotDeclared); }
static void __attribute__((constructor)) phase8_unknown_use(void) {
  io_eff(CID(get), phase8_unknown_run, 0);
}
