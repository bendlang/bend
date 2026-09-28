// Adapted from upstream b2111cf43244e65f76ddc278ee695e669f720cbf.
// Uses the retained selfhost runtime and its CID_* constructor ABI.
// IO
// ==

// The host pool's size, set before the loop runs: --threads, else the CPUs
// this process may use, clamped to 1..CUBE_T.
Term io_thread_count_run(Env e, Term* f, IoWork* w) {
  return (Term)pool_size;
}

static void __attribute__((constructor)) io_thread_count_use(void) {
  io_eff(CID_IO_THREAD_COUNT, io_thread_count_run, 0);
}
