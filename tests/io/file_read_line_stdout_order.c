#include <dlfcn.h>

static int armed_fd = -1;

// The first read of the armed file writes "two" to fd 1 past the runtime,
// so a line IO.print still holds at the read comes out after it.
ssize_t read(int fd, void* data, size_t size) {
  ssize_t (*real)(int, void*, size_t) = dlsym(RTLD_NEXT, "read");
  if (fd == armed_fd) {
    armed_fd = -1;
    if (write(1, "two\n", 4)) {
    }
  }
  return real(fd, data, size);
}

Term read_arm_run(Env e, Term* f, IoWork* w) {
  armed_fd = (int)io_hand_v(f[0]);
  return f[0];
}

// The read is the only helper job, so it is running: if not, the test
// checks nothing. Wait for it to finish without draining the wake pipe or
// flushing stdout on the loop thread, as stdout_file_order.c does.
Term wait_for_read_run(Env e, Term* f, IoWork* w) {
  if (io_busy == 0) {
    err_fail("the file read is not running");
  }
  struct pollfd wake = { .fd = io_wake_fd[0], .events = POLLIN };
  int ready;
  do {
    ready = poll(&wake, 1, 60000);
  } while (ready < 0 && errno == EINTR);
  if (ready != 1 || !(wake.revents & POLLIN)) {
    err_fail("the file read did not finish");
  }
  return term_pak(CID(Unit), 0);
}

static void __attribute__((constructor)) read_order_use(void) {
  io_eff(CID(read_arm), read_arm_run);
  io_eff(CID(wait_for_read), wait_for_read_run);
}
