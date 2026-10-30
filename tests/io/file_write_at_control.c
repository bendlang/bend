#include <dlfcn.h>

static int positioned_fd = -1;
static u32 positioned_stage;
static u32 positioned_mode;
static off_t positioned_next;

// Controlled interruptions and short/zero/error answers, only for this fd.
ssize_t pwrite(int fd, const void* data, size_t size, off_t offset) {
  ssize_t (*real)(int, const void*, size_t, off_t) = dlsym(RTLD_NEXT, "pwrite");
  if (fd == positioned_fd && size > 0) {
    if (offset != positioned_next) {
      err_fail("a positioned retry used the wrong offset");
    }
    u32 stage = positioned_stage++;
    if (positioned_mode == 0 && (stage == 0 || stage == 2)) {
      errno = EINTR;
      return -1;
    }
    if (positioned_mode == 1 && stage == 1) {
      return 0;
    }
    if (positioned_mode == 2 && stage == 1) {
      errno = EACCES;
      return -1;
    }
    if ((positioned_mode == 0 ? stage == 1 : stage == 0) && size > 2) {
      size = 2;
    }
    ssize_t n = real(fd, data, size, offset);
    if (n > 0) {
      positioned_next += n;
    }
    return n;
  }
  return real(fd, data, size, offset);
}

Term positioned_arm_run(Env e, Term* f, IoWork* w) {
  positioned_fd = (int)io_hand_v(f[0]);
  positioned_mode = f[1];
  positioned_stage = 0;
  positioned_next = 17;
  return f[0];
}

Term positioned_check_run(Env e, Term* f, IoWork* w) {
  if (positioned_stage != (positioned_mode == 0 ? 4 : 2)) {
    err_fail("the positioned write did not run every control stage");
  }
  positioned_fd = -1;
  return f[0];
}

static void __attribute__((constructor)) positioned_use(void) {
  io_eff(CID(Control.arm), positioned_arm_run);
  io_eff(CID(Control.check), positioned_check_run);
}
