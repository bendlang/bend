// File
// ====

static void HID(file_write_fill)(IoWork* w, int at_offset) {
  int fd = (int)w->hand;
  ssize_t n = 0;
  for (uint64_t at = 0; n >= 0 && at < w->size; at += (uint64_t)n) {
    do {
      n = at_offset ? pwrite(fd, w->data + at, w->size - at, (off_t)(w->made + at))
                    : write(fd, w->data + at, w->size - at);
    } while (n < 0 && errno == EINTR);
    // no progress would retry forever (#1445)
    if (n == 0) {
      w->code = EIO;
      return;
    }
  }
  io_sys_end(w, n);
}

static void HID(file_write_call)(IoWork* w) {
  HID(file_write_fill)(w, 0);
}

static Term HID(file_write_pack)(Env e, IoWork* w) {
  Term r = io_res(e, w, term_pak(CID(Unit), 0));
  free(w->data);
  return io_tup(e, io_hand(w->hand), r);
}

#ifdef CID(File.write)

Term HID(file_write_run)(Env e, Term* f, IoWork* w) {
  w->hand = (intptr_t)io_hand_v(f[0]);
  w->data = io_cstr(e, f[1], &w->size);
  return io_work(w, HID(file_write_call), HID(file_write_pack));
}

static void __attribute__((constructor)) HID(file_write_use)(void) {
  io_eff(CID(File.write), HID(file_write_run));
}

#endif

#ifdef CID(File.write_bytes)

// A value past 255 fails with EINVAL before any byte is written.
Term HID(file_write_bytes_run)(Env e, Term* f, IoWork* w) {
  w->hand = (intptr_t)io_hand_v(f[0]);
  w->data = io_cbuf(e, f[1], &w->size, CID(Con));
  w->code = w->data == NULL ? EINVAL : 0;
  return w->code ? HID(file_write_pack)(e, w)
    : io_work(w, HID(file_write_call), HID(file_write_pack));
}

static void __attribute__((constructor)) HID(file_write_bytes_use)(void) {
  io_eff(CID(File.write_bytes), HID(file_write_bytes_run));
}

#endif

#ifdef CID(File.write_at)

static void HID(file_write_at_call)(IoWork* w) {
  HID(file_write_fill)(w, 1);
}

Term HID(file_write_at_run)(Env e, Term* f, IoWork* w) {
  w->hand = (intptr_t)io_hand_v(f[0]);
  w->made = (intptr_t)f[1];
  w->data = io_cbuf(e, f[2], &w->size, CID(Con));
  int flags = fcntl((int)w->hand, F_GETFL);
  w->code = w->data == NULL || (flags >= 0 && (flags & O_APPEND)) ? EINVAL : 0;
  return w->code ? HID(file_write_pack)(e, w)
    : io_work(w, HID(file_write_at_call), HID(file_write_pack));
}

static void __attribute__((constructor)) HID(file_write_at_use)(void) {
  io_eff(CID(File.write_at), HID(file_write_at_run));
}

#endif
