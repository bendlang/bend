// IO
// ==

Term io_spawn_run(Env e, Term* f, IoWork* w) {
  io_spawn(f[0]);
  return term_pak(CID_UNIT, 0);
}

static void __attribute__((constructor)) io_spawn_use(void) {
  io_eff(CID_IO_SPAWN, io_spawn_run, 0);
}
