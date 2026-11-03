// IO
// ==

// The host pool's size, set before the loop runs: --threads, else the CPUs
// this process may use, clamped to 1..CUBE_T.
Term HID(io_thread_count_run)(Env e, Term* f, IoWork* w) {
  return (Term)pool_size;
}

static void __attribute__((constructor)) HID(io_thread_count_use)(void) {
  io_eff(CID(IO.thread_count), HID(io_thread_count_run));
}
