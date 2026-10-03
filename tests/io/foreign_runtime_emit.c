static Term native_emit_run(Env e, Term* f, IoWork* w) {
  (void)w;
  u64 at = task_node(e, FID(IO~emit), TERM_HOLE, 0, 0);
  e.mem[at] = f[0];
  Term result = corpus_eval(e.mem, term_tsk(FID(IO~emit), at));
  if (err_seen(e.mem) || term_aux(result) != CID(Emit))
    err_fail("foreign emit failed");
  u64 loc = term_loc(result);
  Term value = e.mem[loc];
  heap_free(e, 0, loc);
  printf("%u\n", (u32)value);
  return term_pak(CID(Unit), 0);
}

static void __attribute__((constructor)) native_emit_use(void) {
  io_eff(CID(native.emit), native_emit_run, 0);
}
