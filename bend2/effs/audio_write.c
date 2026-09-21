// Audio
// =====

// @src audio_ring.c

// The samples (interleaved L R ...) into the ring; the frames queued
// after the write. Past the ring's room, the samples are dropped and
// the queue answered as it is.
Term audio_write_run(Env e, Term* f, IoWork* w) {
  IoRing* p   = (IoRing*)(uintptr_t)io_hand_v(f[0]);
  float   pcm[IO_RING * 2];
  u32     n   = 0;
  Term    s   = f[1];
  while (term_aux(s) == CID_CON) {
    Term fb[2];
    spare_free(e, cls_fit(2), ctr_take(e, s, 2, fb));
    if (n < IO_RING * 2) {
      pcm[n] = f32_unbox(fb[0]);
    }
    n += 1;
    s  = fb[1];
  }
  u64 q = n > IO_RING * 2 ? io_ring_write(p, pcm, 0)
    : io_ring_write(p, pcm, n / 2);
  return io_tup(e, f[0], q);
}

static void __attribute__((constructor)) audio_write_use(void) {
  io_eff(CID_AUDIO_WRITE, audio_write_run, 0);
}
