#ifdef __APPLE__
#include <util.h>
#else
#include <pty.h>
#endif

// A pseudo-terminal cols columns wide: the fd of its terminal side.
Term pty_open_run(Env e, Term* f, IoWork* w) {
  int m = -1, s = -1;
  struct winsize z = { .ws_row = 24, .ws_col = (unsigned short)(u32)f[0] };
  openpty(&m, &s, NULL, NULL, &z);
  return (Term)(u32)s;
}

static void __attribute__((constructor)) pty_open_use(void) {
  io_eff(CID(Pty.open), pty_open_run);
}
