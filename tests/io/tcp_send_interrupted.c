#include <dlfcn.h>

static int interrupted_fd = -1;
static u32 interrupted_stage;

// Interrupt before any progress, then after a two-byte short send.
ssize_t send(int fd, const void* data, size_t size, int flags) {
  ssize_t (*real)(int, const void*, size_t, int) = dlsym(RTLD_NEXT, "send");
  if (fd == interrupted_fd && size > 0) {
    u32 stage = interrupted_stage++;
    if (stage == 0 || stage == 2) {
      errno = EINTR;
      return -1;
    }
    if (stage == 1 && size > 2) {
      size = 2;
    }
  }
  return real(fd, data, size, flags);
}

Term interrupted_pair_run(Env e, Term* f, IoWork* w) {
  int p[2];
  if (socketpair(AF_UNIX, SOCK_STREAM, 0, p)) {
    err_fail("socketpair failed");
  }
  return io_tup(e, io_hand(p[0]), io_hand(p[1]));
}

Term interrupted_arm_run(Env e, Term* f, IoWork* w) {
  interrupted_fd = (int)io_hand_v(f[0]);
  interrupted_stage = 0;
  return f[0];
}

Term interrupted_check_run(Env e, Term* f, IoWork* w) {
  if (interrupted_stage != 4) {
    err_fail("the send did not run every interruption stage");
  }
  interrupted_fd = -1;
  return f[0];
}

static void __attribute__((constructor)) interrupted_use(void) {
  io_eff(CID(Interrupted.pair), interrupted_pair_run);
  io_eff(CID(Interrupted.arm), interrupted_arm_run);
  io_eff(CID(Interrupted.check), interrupted_check_run);
}
