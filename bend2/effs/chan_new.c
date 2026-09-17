// Chan
// ====

Term chan_new_run(Env e, Term* f, IoWork* w) {
  return chan_open((u32)f[0]);
}

static void __attribute__((constructor)) chan_new_use(void) {
  io_eff(CID_CHAN_NEW, chan_new_run, 0);
}
