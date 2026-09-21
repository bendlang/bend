// Audio
// =====

// @src audio_ring.c

Term audio_open_run(Env e, Term* f, IoWork* w) {
  u32     rate = (u32)f[0];
  IoRing* p    = io_mem(calloc(1, sizeof *p));
  u32     code = rate < 8000 || rate > 192000 ? EINVAL : io_ring_start(p, rate);
  if (code != 0) {
    io_ring_free(p);
    return io_fail(e, code, code == EINVAL ? NULL : "Audio.open: no audio output");
  }
  return io_done(e, io_hand((intptr_t)p));
}

static void __attribute__((constructor)) audio_open_use(void) {
  io_eff(CID_AUDIO_OPEN, audio_open_run, 0);
}
