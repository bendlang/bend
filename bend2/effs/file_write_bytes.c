// File
// ====

static void file_write_bytes_call(IoWork* w) {
  for (u64 at = 0; at < w->size;) {
    u64 left = w->size - at;
    ssize_t n = write((int)w->hand, w->data + at,
      left < INT32_MAX ? left : INT32_MAX);
    if (n < 0 && errno == EINTR) continue;
    if (n <= 0) {
      w->code = n < 0 ? (u32)errno : EIO;
      return;
    }
    at += (u64)n;
  }
}

static Term file_write_bytes_pack(Env e, IoWork* w) {
  Term r = w->code ? io_fail(e, w->code, NULL)
    : io_done(e, term_pak(CID_UNIT, 0));
  free(w->data);
  return io_tup(e, io_hand(w->hand), r);
}

Term file_write_bytes_run(Env e, Term* f, IoWork* w) {
  w->code = 0;
  w->hand = (intptr_t)io_hand_v(f[0]);
  w->size = 0;
  w->data = NULL;
  u64 cap = 0;
  Term xs = f[1];
  while (term_aux(xs) == CID_CON) {
    Term fb[2];
    spare_free(e, cls_fit(2), ctr_take(e, xs, 2, fb));
    xs = fb[1];
    if (fb[0] > 255) {
      w->code = EINVAL;
      break;
    }
    if (w->size == cap) {
      cap = cap ? cap * 2 : 64;
      char* data = realloc(w->data, cap);
      if (data == NULL) {
        w->code = ENOMEM;
        break;
      }
      w->data = data;
    }
    w->data[w->size++] = (char)fb[0];
  }
  term_drop(e, xs);
  if (w->code || w->size == 0) return file_write_bytes_pack(e, w);
  return io_work(w, file_write_bytes_call, file_write_bytes_pack);
}

static void __attribute__((constructor)) file_write_bytes_use(void) {
  io_eff(CID_FILE_WRITE_BYTES, file_write_bytes_run, 0);
}
