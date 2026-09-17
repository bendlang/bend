// File
// ====

static void file_read_call(IoWork* w) {
  int fd = (int)w->hand;
  w->size = io_sys_end(w, read(fd, w->data, w->word));
}

static Term file_read_pack(Env e, IoWork* w) {
  Term r = w->code ? io_fail(e, w->code, NULL)
    : io_done(e, io_str(e, w->data, w->size));
  free(w->data);
  return io_tup(e, io_hand(w->hand), r);
}

Term file_read_run(Env e, Term* f, IoWork* w) {
  w->hand = (intptr_t)io_hand_v(f[0]);
  w->word = f[1] < INT32_MAX ? f[1] : INT32_MAX;
  w->data = io_mem(malloc(w->word + 1));
  return io_work(w, file_read_call, file_read_pack);
}

static void __attribute__((constructor)) file_read_use(void) {
  io_eff(CID_FILE_READ, file_read_run, 0);
}
