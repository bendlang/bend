// IO
// ==

// A tty stream per fd, made once. A stream reads its size only when made,
// so each call has it read again (_refreshSize, which Node and Bun run for
// stdout on SIGWINCH): the width is the terminal's now, as on C.
const IO_TTYS = [];

function io_terminal_width(fd) {
  const tty = require("tty");
  if (!tty.isatty(fd)) {
    return 0;
  }
  const s = IO_TTYS[fd] ??= new tty.WriteStream(fd);
  s._refreshSize();
  return s.columns ?? 0;
}

io_eff(CID(IO.terminal_width), io_terminal_width);
