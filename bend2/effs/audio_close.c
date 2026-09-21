// Audio
// =====

// @src audio_ring.c

Term audio_close_run(Env e, Term* f, IoWork* w) {
  io_ring_free((IoRing*)(uintptr_t)io_hand_v(f[0]));
  return term_pak(CID_UNIT, 0);
}

static void __attribute__((constructor)) audio_close_use(void) {
  io_eff(CID_AUDIO_CLOSE, audio_close_run, 0);
}
