// File
// ====

static void file_write_call(IoWork* w) {
  int fd = (int)w->hand;
  ssize_t n = 0;
  for (uint64_t at = 0; n >= 0 && at < w->size; at += (uint64_t)n) {
    n = write(fd, w->data + at, w->size - at);
  }
  io_sys_end(w, n);
}

static Term file_write_pack(Env e, IoWork* w) {
  Term r = w->code != 0 ? io_fail(e, w->code, NULL)
    : io_done(e, term_pak(CID_UNIT, 0));
  free(w->data);
  return io_tup(e, io_hand(w->hand), r);
}

#ifdef CID_FILE_WRITE

Term file_write_run(Env e, Term* f, IoWork* w) {
  w->hand = (intptr_t)io_hand_v(f[0]);
  w->data = io_cstr(e, f[1], &w->size);
  return io_work(w, file_write_call, file_write_pack);
}

static void __attribute__((constructor)) file_write_use(void) {
  io_eff(CID_FILE_WRITE, file_write_run, 0);
}

#endif

#ifdef CID_FILE_WRITE_BYTES

// The bytes as they are (0..255), one List cell each; a value past 255
// fails with EINVAL before any byte is written.
Term file_write_bytes_run(Env e, Term* f, IoWork* w) {
  u64  cap = 64;
  Term xs  = f[1];
  w->hand = (intptr_t)io_hand_v(f[0]);
  w->code = 0;
  w->size = 0;
  w->data = io_mem(malloc(cap));
  while (term_aux(xs) == CID_CON) {
    Term fb[2];
    spare_free(e, cls_fit(2), ctr_take(e, xs, 2, fb));
    if (w->size == cap) {
      cap *= 2;
      w->data = io_mem(realloc(w->data, cap));
    }
    w->code = fb[0] > 255 ? EINVAL : w->code;
    w->data[w->size++] = (char)fb[0];
    xs = fb[1];
  }
  return w->code ? file_write_pack(e, w)
    : io_work(w, file_write_call, file_write_pack);
}

static void __attribute__((constructor)) file_write_bytes_use(void) {
  io_eff(CID_FILE_WRITE_BYTES, file_write_bytes_run, 0);
}

#endif
