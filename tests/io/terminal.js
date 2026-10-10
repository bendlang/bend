// A pseudo-terminal cols columns wide: the fd of its terminal side.
function pty_open(cols) {
  const ffi = require("bun:ffi");
  const sys = io_sys();
  const lib = ffi.dlopen(sys.mac ? "libSystem.dylib" : "libc.so.6", {
    openpty: { args: ["ptr", "ptr", "ptr", "ptr", "ptr"], returns: "i32" },
  }).symbols;
  const fd = new Int32Array([-1, -1]);
  lib.openpty(ffi.ptr(fd), ffi.ptr(fd, 4), null, null,
    ffi.ptr(new Uint16Array([24, cols, 0, 0])));
  return fd[1];
}

io_eff(CID(Pty.open), pty_open);
