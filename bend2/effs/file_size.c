// File
// ====

#include <sys/stat.h>

// Read the host size once; each pack chooses the U32 or hi/lo result.
static void file_size_call(IoWork* w) {
  struct stat st;
  int n = fstat((int)w->hand, &st);
  io_sys_end(w, n);
  if (n == 0) {
    w->size = (u64)st.st_size;
  }
}

#ifdef CID(File.size)

static Term file_size_pack(Env e, IoWork* w) {
  if (w->code == 0 && w->size > UINT32_MAX) w->code = EOVERFLOW;
  return io_tup(e, io_hand(w->hand), io_res(e, w, w->code ? 0 : (u32)w->size));
}

Term file_size_run(Env e, Term* f, IoWork* w) {
  w->hand = (intptr_t)io_hand_v(f[0]);
  return io_work(w, file_size_call, file_size_pack);
}

static void __attribute__((constructor)) file_size_use(void) {
  io_eff(CID(File.size), file_size_run);
}

#endif

#ifdef CID(File.size64)

static Term file_size64_pack(Env e, IoWork* w) {
  if (w->code == 0 && w->size > INT64_MAX) w->code = EOVERFLOW;
  Term size = w->code ? 0 : io_tup(e, (u32)(w->size >> 32), (u32)w->size);
  return io_tup(e, io_hand(w->hand), io_res(e, w, size));
}

Term file_size64_run(Env e, Term* f, IoWork* w) {
  w->hand = (intptr_t)io_hand_v(f[0]);
  return io_work(w, file_size_call, file_size64_pack);
}

static void __attribute__((constructor)) file_size64_use(void) {
  io_eff(CID(File.size64), file_size64_run);
}

#endif
