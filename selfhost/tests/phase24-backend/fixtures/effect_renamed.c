Term answer_run(Env e, Term* f, IoWork* w) { return 7; }
static void __attribute__((constructor)) answer_use(void) { io_eff(CID(Tock), answer_run, 0); }
