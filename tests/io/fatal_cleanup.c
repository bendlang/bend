#include <sys/resource.h>
#include <sys/wait.h>

static int fatal_cleanup_fd = -1;
static volatile sig_atomic_t fatal_cleanup_fault;

static void fatal_cleanup_record(void) {
  char byte = 'x';
  while (write(fatal_cleanup_fd, &byte, 1) < 0 && errno == EINTR) {}
  if (fatal_cleanup_fault) raise(SIGBUS);
}

static u32 fatal_cleanup_case(u32 mode) {
  int pipe_fd[2];
  if (pipe(pipe_fd)) return 1u << mode;
  pid_t child = fork();
  if (child < 0) {
    close(pipe_fd[0]);
    close(pipe_fd[1]);
    return 1u << mode;
  }
  if (child == 0) {
    close(pipe_fd[0]);
    fatal_cleanup_fd = pipe_fd[1];
    struct rlimit limit = { 0, 0 };
    if (setrlimit(RLIMIT_CORE, &limit)) _exit(98);
    int sink = open("/dev/null", O_WRONLY);
    if (sink < 0 || dup2(sink, 2) < 0) _exit(97);
    if (sink != 2) close(sink);
    if (mode == 3) exit(0);
    fatal_cleanup_fault = mode == 4;
    if (mode == 0 || mode == 4) err_fail("cleanup probe");
    raise(mode == 1 ? SIGSEGV : SIGBUS);
    _exit(99);
  }
  close(pipe_fd[1]);
  u32 count = 0;
  char bytes[2];
  ssize_t got;
  while ((got = read(pipe_fd[0], bytes, sizeof bytes)) != 0) {
    if (got < 0) {
      if (errno == EINTR) continue;
      count = 99;
      break;
    }
    count += (u32)got;
  }
  close(pipe_fd[0]);
  int status;
  pid_t waited;
  do { waited = waitpid(child, &status, 0); } while (waited < 0 && errno == EINTR);
  bool ok = waited == child && count == (mode == 3 ? 0u : 1u);
  if (mode == 0 || mode == 3) {
    ok = ok && WIFEXITED(status) && WEXITSTATUS(status) == (mode == 0 ? 1 : 0);
  } else {
    ok = ok && WIFSIGNALED(status) && WTERMSIG(status) == (mode == 1 ? SIGSEGV : SIGBUS);
  }
  return ok ? 0 : 1u << mode;
}

static Term fatal_cleanup_test(Env e, Term* f, IoWork* w) {
  u32 failed = 0;
  for (u32 mode = 0; mode < 5; ++mode) failed |= fatal_cleanup_case(mode);
  return failed;
}

__attribute__((constructor)) static void fatal_cleanup_use(void) {
  err_cleanup = fatal_cleanup_record;
  io_eff(CID(FatalCleanup.test), fatal_cleanup_test);
}
