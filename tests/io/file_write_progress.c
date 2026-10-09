#include <dlfcn.h>

// Only this fixture's descriptor is affected. Positive writes still reach
// the real filesystem; the second nonempty call models a stalled device.
typedef ssize_t (*ProgressWrite)(int, const void*, size_t);
static ProgressWrite progress_write;
static int progress_fd = -1;
static unsigned progress_calls;
static bool progress_forever;
static bool progress_zero;

ssize_t write(int fd, const void* data, size_t size) {
  if (progress_write == NULL) {
    progress_write = (ProgressWrite)dlsym(RTLD_NEXT, "write");
    if (progress_write == NULL) {
      errno = EIO;
      return -1;
    }
  }
  if (fd == progress_fd && size > 0) {
    if (progress_zero && progress_calls == 1) {
      progress_calls = 2;
      return 0;
    }
    if (progress_zero && progress_forever && progress_calls >= 2) {
      return 0;
    }
    progress_calls += 1;
    size = size > 7 ? 7 : size;
  }
  return progress_write(fd, data, size);
}

Term progress_open_run(Env e, Term* f, IoWork* w) {
  const char* dir = getenv("TMPDIR");
  dir = dir == NULL ? "/tmp" : dir;
  const char suffix[] = "/bend-write-progress-XXXXXX";
  size_t n = strlen(dir);
  char* path = io_mem(malloc(n + sizeof(suffix)));
  memcpy(path, dir, n);
  memcpy(path + n, suffix, sizeof(suffix));
  int fd = mkstemp(path);
  int code = fd < 0 ? errno : 0;
  if (fd >= 0 && unlink(path) != 0) {
    code = errno;
    close(fd);
    fd = -1;
  }
  free(path);
  if (fd < 0) {
    return io_fail(e, (u32)code, NULL);
  }
  progress_fd = fd;
  progress_calls = 0;
  progress_zero = true;
  progress_forever = getenv("BEND_TEST_WRITE_ZERO_FOREVER") != NULL;
  return io_done(e, io_hand(fd));
}

Term progress_resume_run(Env e, Term* f, IoWork* w) {
  progress_zero = false;
  return term_pak(CID(Unit), 0);
}

Term progress_release_run(Env e, Term* f, IoWork* w) {
  progress_fd = -1;
  return term_pak(CID(Unit), 0);
}

static void __attribute__((constructor)) progress_use(void) {
  io_eff(CID(Progress.open), progress_open_run);
  io_eff(CID(Progress.resume), progress_resume_run);
  io_eff(CID(Progress.release), progress_release_run);
}
