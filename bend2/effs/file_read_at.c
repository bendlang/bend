// File
// ====

static void file_read_at_call(IoWork* w) {
  ssize_t n;
  do {
    n = pread((int)w->hand, w->data, w->word, (off_t)w->made);
  } while (n < 0 && errno == EINTR);
  w->size = io_sys_end(w, n);
}

static Term file_read_at_pack(Env e, IoWork* w) {
  Term r;
  if (w->code) {
    r = io_fail(e, w->code, NULL);
  } else {
    Term xs = term_pak(CID_NIL, 0);
    for (u64 i = w->size; i > 0; i -= 1) {
      xs = io_node(e, CID_CON, ((uint8_t*)w->data)[i - 1], xs, IO_HOTS & 16);
    }
    r = io_done(e, xs);
  }
  free(w->data);
  return io_tup(e, io_hand(w->hand), r);
}

Term file_read_at_run(Env e, Term* f, IoWork* w) {
  w->code = 0;
  w->hand = (intptr_t)io_hand_v(f[0]);
  w->made = (intptr_t)f[1];
  w->word = f[2] < INT32_MAX ? f[2] : INT32_MAX;
  w->size = 0;
  w->data = NULL;
  if (w->word == 0) return file_read_at_pack(e, w);
  w->data = malloc(w->word);
  if (w->data == NULL) {
    w->code = ENOMEM;
    return file_read_at_pack(e, w);
  }
  return io_work(w, file_read_at_call, file_read_at_pack);
}

static void __attribute__((constructor)) file_read_at_use(void) {
  io_eff(CID_FILE_READ_AT, file_read_at_run, 0);
}
