#include <dlfcn.h>
#include <poll.h>

static int interrupted_fd = -1;
static u32 interrupted_stage;

ssize_t sendto(int fd, const void* data, size_t size, int flags,
  const struct sockaddr* addr, socklen_t len) {
  if (fd == interrupted_fd && interrupted_stage++ < 2) {
    errno = EINTR;
    return -1;
  }
  ssize_t (*real)(int, const void*, size_t, int, const struct sockaddr*, socklen_t)
    = dlsym(RTLD_NEXT, "sendto");
  return real(fd, data, size, flags, addr, len);
}

Term interrupted_port_run(Env e, Term* f, IoWork* w) {
  int fd = (int)io_hand_v(f[0]);
  struct sockaddr_in addr;
  socklen_t len = sizeof(addr);
  if (getsockname(fd, (struct sockaddr*)&addr, &len)) {
    err_fail("getsockname failed");
  }
  return io_tup(e, f[0], ntohs(addr.sin_port));
}

Term interrupted_arm_run(Env e, Term* f, IoWork* w) {
  interrupted_fd = (int)io_hand_v(f[0]);
  interrupted_stage = 0;
  return f[0];
}

Term interrupted_check_run(Env e, Term* f, IoWork* w) {
  int fd = (int)io_hand_v(f[0]);
  interrupted_fd = -1;
  struct pollfd ready = {fd, POLLIN, 0};
  char data[64];
  const u8 want[] = {97, 195, 169, 206, 187, 122};
  if (interrupted_stage != 3 || poll(&ready, 1, 1000) != 1
    || recv(fd, data, sizeof(data), 0) != sizeof(want)
    || memcmp(data, want, sizeof(want)) != 0) {
    err_fail("the interrupted datagram was not sent exactly once");
  }
  return f[0];
}

static void __attribute__((constructor)) interrupted_use(void) {
  io_eff(CID(Interrupted.port), interrupted_port_run);
  io_eff(CID(Interrupted.arm), interrupted_arm_run);
  io_eff(CID(Interrupted.check), interrupted_check_run);
}
