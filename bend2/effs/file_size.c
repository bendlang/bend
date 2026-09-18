// File
// ====

#include <sys/stat.h>

static void file_size_call(IoWork* w) {
  struct stat st;
  int n;
  do {
    n = fstat((int)w->hand, &st);
  } while (n < 0 && errno == EINTR);
  io_sys_end(w, n);
  if (n < 0) return;
  if (st.st_size < 0 || (uint64_t)st.st_size >= (1ull << 48)) {
    w->code = EOVERFLOW;
    return;
  }
  w->size = (u64)st.st_size;
}

static Term file_size_pack(Env e, IoWork* w) {
  Term r = w->code ? io_fail(e, w->code, NULL) : io_done(e, w->size);
  return io_tup(e, io_hand(w->hand), r);
}

Term file_size_run(Env e, Term* f, IoWork* w) {
  w->hand = (intptr_t)io_hand_v(f[0]);
  return io_work(w, file_size_call, file_size_pack);
}

static void __attribute__((constructor)) file_size_use(void) {
  io_eff(CID_FILE_SIZE, file_size_run, 0);
}
