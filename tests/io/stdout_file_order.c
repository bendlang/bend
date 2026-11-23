Term wait_for_write_run(Env e, Term* f, IoWork* w) {
  // The write is the only helper job, so it is running: if not, the test
  // checks nothing. Wait for it to finish (a minute: a stuck write fails,
  // a slow one does not) without draining the wake pipe or flushing stdout
  // on the loop thread.
  if (io_busy == 0) {
    err_fail("the file write is not running");
  }
  struct pollfd wake = { .fd = io_wake_fd[0], .events = POLLIN };
  int ready;
  do {
    ready = poll(&wake, 1, 60000);
  } while (ready < 0 && errno == EINTR);
  if (ready != 1 || !(wake.revents & POLLIN)) {
    err_fail("the file write did not finish");
  }
  return term_pak(CID(Unit), 0);
}

static void __attribute__((constructor)) wait_for_write_use(void) {
  io_eff(CID(wait_for_write), wait_for_write_run);
}
