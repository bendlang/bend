#include <dlfcn.h>

static int interrupted_fd = -1;
static u32 interrupted_stage;

// Interrupt the first recv, then let the retry read for real.
ssize_t recv(int fd, void* data, size_t size, int flags) {
  ssize_t (*real)(int, void*, size_t, int) = dlsym(RTLD_NEXT, "recv");
  if (fd == interrupted_fd && size > 0 && interrupted_stage++ == 0) {
    errno = EINTR;
    return -1;
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
  if (interrupted_stage != 2) {
    err_fail("the recv did not retry after its interruption");
  }
  interrupted_fd = -1;
  return f[0];
}

static void __attribute__((constructor)) interrupted_use(void) {
  io_eff(CID(Interrupted.pair), interrupted_pair_run);
  io_eff(CID(Interrupted.arm), interrupted_arm_run);
  io_eff(CID(Interrupted.check), interrupted_check_run);
}
