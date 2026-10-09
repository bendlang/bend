// IO
// ==

#ifdef CID(IO.now)

Term io_now_run(Env e, Term* f, IoWork* w) {
  return (Term)(io_tick() / 1000000);
}

static void __attribute__((constructor)) io_now_use(void) {
  io_eff(CID(IO.now), io_now_run);
}

#endif

#ifdef CID(IO.clock)

Term io_clock_run(Env e, Term* f, IoWork* w) {
  struct timespec ts;
  clockid_t clock = f[0] == term_pak(CID(Wall), 0)
    ? CLOCK_REALTIME : CLOCK_MONOTONIC;
  if (clock_gettime(clock, &ts) != 0) {
    err_fail("the host clock could not be read");
  }
  if ((u64)ts.tv_sec >> 48) {
    err_fail("a clock second count outside Nat's range");
  }
  return io_tup(e, (Term)ts.tv_sec, (Term)ts.tv_nsec);
}

static void __attribute__((constructor)) io_clock_use(void) {
  io_eff(CID(IO.clock), io_clock_run);
}

#endif
