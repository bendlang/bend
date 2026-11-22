static Term pmake_at(Env e, u32 d) {
  if (d == 0) {
    return term_pak(CID(Pe), 0);
  }
  u64 l = heap_alloc(e, 3);
  e.mem[l] = d & 1;
  e.mem[l + 1] = pmake_at(e, d - 1);
  e.mem[l + 2] = 0xF0000000u + d;
  e.mem[l + 3] = (d >> 1) & 1;
  e.mem[l + 4] = pmake_at(e, d - 1);
  return term_ctr(CID(Pn), l);
}

static Term pmake_run(Env e, Term* f, IoWork* w) {
  (void)w;
  return pmake_at(e, (u32)f[0]);
}

static void __attribute__((constructor)) pmake_use(void) {
  io_eff(CID(pmake), pmake_run);
}
