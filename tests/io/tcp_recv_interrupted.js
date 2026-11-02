let interrupted_fd = -1;
let interrupted_stage = 0;
let interrupted_real;
let interrupted_errno;
let interrupted_pending = false;

function interrupted_pair() {
  const sys = io_sys();
  const ffi = require("bun:ffi");
  const lib = ffi.dlopen(sys.mac ? "libSystem.dylib" : "libc.so.6", {
    socketpair: { args: ["i32", "i32", "i32", "ptr"], returns: "i32" },
  });
  const p = new Int32Array(2);
  if (lib.symbols.socketpair(1, 1, 0, sys.ptr(p))) {
    throw new Error("socketpair failed");
  }
  return io_tup(p[0], p[1]);
}

// Interrupt the first recv, then let the retry read for real.
function interrupted_arm(socket) {
  const sys = io_sys();
  interrupted_fd = socket;
  interrupted_stage = 0;
  if (interrupted_real === undefined) {
    interrupted_real = sys.recv;
    interrupted_errno = sys.errno;
    sys.errno = () => interrupted_pending ? 4 : interrupted_errno();
    sys.recv = (fd, data, size, flags) => {
      interrupted_pending = false;
      if (fd === interrupted_fd && size > 0 && interrupted_stage++ === 0) {
        interrupted_pending = true;
        return -1;
      }
      return interrupted_real(fd, data, size, flags);
    };
  }
  return socket;
}

function interrupted_check(socket) {
  if (interrupted_stage !== 2) {
    throw new Error("the recv did not retry after its interruption");
  }
  interrupted_fd = -1;
  return socket;
}

io_eff(CID(Interrupted.pair), interrupted_pair);
io_eff(CID(Interrupted.arm), interrupted_arm);
io_eff(CID(Interrupted.check), interrupted_check);
