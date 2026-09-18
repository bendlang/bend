#if defined(__linux__)
#include <sys/random.h>
#endif

static void io_random_u32_call(IoWork* w) {
  uint8_t bytes[4];
  w->code = 0;
#if defined(__linux__)
  size_t used = 0;
  while (used < sizeof(bytes)) {
    ssize_t n = getrandom(bytes + used, sizeof(bytes) - used, 0);
    if (n < 0 && errno == EINTR) {
      continue;
    }
    if (n <= 0) {
      w->code = n < 0 ? (u32)errno : (u32)EIO;
      return;
    }
    used += (size_t)n;
  }
#elif defined(__APPLE__)
  arc4random_buf(bytes, sizeof(bytes));
#else
  w->code = ENOSYS;
  return;
#endif
  w->word = (uint32_t)bytes[0]
    | ((uint32_t)bytes[1] << 8)
    | ((uint32_t)bytes[2] << 16)
    | ((uint32_t)bytes[3] << 24);
}

static Term io_random_u32_pack(Env e, IoWork* w) {
  return w->code != 0 ? io_fail(e, w->code, NULL) : io_done(e, w->word);
}

Term io_random_u32_run(Env e, Term* f, IoWork* w) {
  return io_work(w, io_random_u32_call, io_random_u32_pack);
}

static void __attribute__((constructor)) io_random_u32_use(void) {
  io_eff(CID_IO_RANDOM_U32, io_random_u32_run, 0);
}
