#include <dlfcn.h>

static int  armed_fd = -1;
static bool flushed;

// Notes a flush of stdout, so the armed read can tell whether the runtime
// flushed what IO.print held before it read.
int fflush(FILE* h) {
  int (*real)(FILE*) = dlsym(RTLD_NEXT, "fflush");
  flushed = flushed || h == stdout;
  return real(h);
}

ssize_t read(int fd, void* data, size_t size) {
  ssize_t (*real)(int, void*, size_t) = dlsym(RTLD_NEXT, "read");
  if (fd == armed_fd) {
    armed_fd = -1;
    if (!flushed) {
      err_fail("the read ran with stdout still held");
    }
  }
  return real(fd, data, size);
}

Term read_arm_run(Env e, Term* f, IoWork* w) {
  armed_fd = (int)io_hand_v(f[0]);
  flushed  = false;
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
