// File
// ====

static void file_read_call(IoWork* w) {
  int fd = (int)w->hand;
  w->size = io_sys_end(w, read(fd, w->data, w->word));
}

static Term file_read_start(Term file, u64 max, IoWork* w,
  IoCall call, IoPack pack) {
  w->hand = (intptr_t)io_hand_v(file);
  w->word = max < INT32_MAX ? max : INT32_MAX;
  w->data = io_mem(malloc(w->word + 1));
  return io_work(w, call, pack);
}

#ifdef CID(File.read)

static Term file_read_pack(Env e, IoWork* w) {
  Term r = io_res(e, w, io_str(e, w->data, w->size));
  free(w->data);
  return io_tup(e, io_hand(w->hand), r);
}

Term file_read_run(Env e, Term* f, IoWork* w) {
  return file_read_start(f[0], f[1], w, file_read_call, file_read_pack);
}

static void __attribute__((constructor)) file_read_use(void) {
  io_eff(CID(File.read), file_read_run);
}

#endif

#if defined(CID(File.read_bytes)) || defined(CID(File.read_at))

static Term file_read_bytes_pack(Env e, IoWork* w) {
  Term r = io_res(e, w, io_list(e, w->data, w->size));
  free(w->data);
  return io_tup(e, io_hand(w->hand), r);
}

#endif

#ifdef CID(File.read_bytes)

Term file_read_bytes_run(Env e, Term* f, IoWork* w) {
  return file_read_start(f[0], f[1], w, file_read_call, file_read_bytes_pack);
}

static void __attribute__((constructor)) file_read_bytes_use(void) {
  io_eff(CID(File.read_bytes), file_read_bytes_run);
}

#endif

#ifdef CID(File.read_at)

// The bytes at an offset, as file_read_bytes gives them; the position of
// the file does not move.
static void file_read_at_call(IoWork* w) {
  int fd = (int)w->hand;
  w->size = io_sys_end(w, pread(fd, w->data, w->word, (off_t)w->made));
}

Term file_read_at_run(Env e, Term* f, IoWork* w) {
  w->made = (intptr_t)f[1];
  return file_read_start(f[0], f[2], w, file_read_at_call, file_read_bytes_pack);
}

static void __attribute__((constructor)) file_read_at_use(void) {
  io_eff(CID(File.read_at), file_read_at_run);
}

#endif

#ifdef CID(File.read_into)

// An Array<U32> block packs its slots little-endian, two to a 64-bit word,
// so slot i is byte 4i of the block: the bytes land there as the file holds
// them, with no List between. A forked handle writes the shared cells, as
// Array.set does. On a GPU the block is already in the device's buffer.
static void file_read_into_call(IoWork* w) {
  u64 got = 0;
  while (got < w->word) {
    u64     want = w->word - got;
    ssize_t n    = pread((int)w->hand, w->data + got,
      want < (1u << 30) ? want : (1u << 30), (off_t)w->made + (off_t)got);
    if (n <= 0) {
      if (n < 0) {
        io_sys_end(w, n);
      }
      break;
    }
    got += (u64)n;
  }
  w->size = got;
}

static Term file_read_into_pack(Env e, IoWork* w) {
  Term r = io_res(e, w, w->size);
  return io_tup(e, io_hand(w->hand), io_tup(e, w->item, r));
}

Term file_read_into_run(Env e, Term* f, IoWork* w) {
  Term a    = f[3];
  u64  at   = (u32)f[4];
  u64  n    = 1ull << blk_cls(a);
  u64  room = at < n ? (n - at) * 4 : 0;
  w->hand = (intptr_t)io_hand_v(f[0]);
  w->made = (intptr_t)(u32)f[1];
  w->word = (u32)f[2] < room ? (u32)f[2] : (u32)room;
  w->item = a;
  w->code = 0;
  w->data = (char*)&e.mem[blk_loc(e.mem, a)] + at * 4;
  return io_work(w, file_read_into_call, file_read_into_pack);
}

static void __attribute__((constructor)) file_read_into_use(void) {
  io_eff(CID(File.read_into), file_read_into_run);
}

#endif
