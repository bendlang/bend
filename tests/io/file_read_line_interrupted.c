#include <dlfcn.h>

static int interrupted_fd = -1;
static u32 interrupted_stage;

// Interrupt the first read of one file, before any byte arrives.
ssize_t read(int fd, void* data, size_t size) {
  ssize_t (*real)(int, void*, size_t) = dlsym(RTLD_NEXT, "read");
  if (fd == interrupted_fd && interrupted_stage++ == 0) {
    errno = EINTR;
    return -1;
  }
  return real(fd, data, size);
}

Term interrupted_arm_run(Env e, Term* f, IoWork* w) {
  interrupted_fd = (int)io_hand_v(f[0]);
  interrupted_stage = 0;
  return f[0];
}

Term interrupted_check_run(Env e, Term* f, IoWork* w) {
  if (interrupted_stage < 2) {
    err_fail("the read was not interrupted and retried");
  }
  interrupted_fd = -1;
  return f[0];
}

static void __attribute__((constructor)) interrupted_use(void) {
  io_eff(CID(Interrupted.arm), interrupted_arm_run);
  io_eff(CID(Interrupted.check), interrupted_check_run);
}
