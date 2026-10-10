// IO
// ==

function io_is_terminal(fd) {
  return require("tty").isatty(fd);
}

io_eff(CID(IO.is_terminal), io_is_terminal);
