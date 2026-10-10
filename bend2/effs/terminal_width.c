// IO
// ==

#include <sys/ioctl.h>

// The width TIOCGWINSZ reports: 0 when fd is no terminal, or the terminal
// does not know its width.
Term io_terminal_width_run(Env e, Term* f, IoWork* w) {
  struct winsize s;
  return (Term)(ioctl((int)(u32)f[0], TIOCGWINSZ, &s) == 0 ? s.ws_col : 0);
}

static void __attribute__((constructor)) io_terminal_width_use(void) {
  io_eff(CID(IO.terminal_width), io_terminal_width_run);
}
