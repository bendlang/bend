#include <dlfcn.h>
#include <stdarg.h>

static int interrupted_stage = -1;

// Interrupt two opens of /dev/null, then return the system call's result.
int open(const char* path, int flags, ...) {
  int (*real)(const char*, int, ...) = dlsym(RTLD_NEXT, "open");
  mode_t mode = 0;
  if (flags & O_CREAT) {
    va_list args;
    va_start(args, flags);
    mode = va_arg(args, int);
    va_end(args);
  }
  if (interrupted_stage >= 0 && strcmp(path, "/dev/null") == 0) {
    if (interrupted_stage++ < 2) {
      errno = EINTR;
      return -1;
    }
    if (interrupted_stage > 3) {
      err_fail("open retried a result other than EINTR");
    }
  }
  return real(path, flags, mode);
}

Term interrupted_arm_run(Env e, Term* f, IoWork* w) {
  interrupted_stage = 0;
  return term_pak(CID(Unit), 0);
}

Term interrupted_check_run(Env e, Term* f, IoWork* w) {
  if (interrupted_stage != 3) {
    err_fail("open did not retry both interruptions");
  }
  interrupted_stage = -1;
  return term_pak(CID(Unit), 0);
}

static void __attribute__((constructor)) interrupted_use(void) {
  io_eff(CID(Interrupted.arm), interrupted_arm_run);
  io_eff(CID(Interrupted.check), interrupted_check_run);
}
