// The JS lane never links Xlib, so it always reports it absent.
function x11_absent() {
  return true;
}

io_eff(CID(x11.absent), x11_absent);
