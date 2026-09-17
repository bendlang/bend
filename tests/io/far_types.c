// Far
// ===

// The constructors are named by this module's file, far_types, from
// wherever the program importing it sits.
static Term far_make_at(Env e, u32 depth, u32* next) {
  if (depth == 0) {
    *next += 1;
    return term_pak(CID_NEAR, *next);
  }
  Term l = far_make_at(e, depth - 1, next);
  Term r = far_make_at(e, depth - 1, next);
  return io_node(e, CID_DEEP, l, r, 0);
}

Term far_make_run(Env e, Term* f, IoWork* w) {
  u32 next = 0;
  return far_make_at(e, (u32)f[0], &next);
}

static void __attribute__((constructor)) far_make_use(void) {
  io_eff(CID_FAR_MAKE, far_make_run, 0);
}
