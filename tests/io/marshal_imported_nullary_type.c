// Tag
// ===

// The macros are this module's spelling, from wherever the program sits.
Term tag_off_run(Env e, Term* f, IoWork* w) {
  return term_pak(CID_OFF, 0);
}

Term tag_on_run(Env e, Term* f, IoWork* w) {
  return term_pak(CID_ON, 3);
}

static void __attribute__((constructor)) tag_use(void) {
  io_eff(CID_TAG_OFF, tag_off_run, 0);
  io_eff(CID_TAG_ON, tag_on_run, 0);
}
