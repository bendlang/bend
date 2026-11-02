let interrupted_armed = false;
let interrupted_calls = 0;
let interrupted_real;
let interrupted_errno;
let interrupted_pending = false;

function interrupted_port(listener) {
  const sys = io_sys();
  const ffi = require("bun:ffi");
  const lib = ffi.dlopen(sys.mac ? "libSystem.dylib" : "libc.so.6", {
    getsockname: { args: ["i32", "ptr", "ptr"], returns: "i32" },
  });
  const addr = new Uint8Array(16);
  const len = new Uint32Array([16]);
  const got = lib.symbols.getsockname(listener, sys.ptr(addr), sys.ptr(len));
  lib.close();
  if (got < 0) {
    throw new Error("getsockname failed");
  }
  return io_tup(listener, (addr[2] << 8) | addr[3]);
}

// A signal that cuts a connect leaves it going on in the background: start
// the real connect, then answer EINTR as the interrupted call would.
function interrupted_arm(listener) {
  const sys = io_sys();
  interrupted_armed = true;
  interrupted_calls = 0;
  if (interrupted_real === undefined) {
    interrupted_real = sys.connect;
    interrupted_errno = sys.errno;
    // The faked EINTR answers only the errno read that follows the connect.
    sys.errno = () => {
      if (interrupted_pending) {
        interrupted_pending = false;
        return 4;
      }
      return interrupted_errno();
    };
    sys.connect = (...args) => {
      interrupted_pending = false;
      const r = interrupted_real(...args);
      if (interrupted_armed && interrupted_calls++ === 0
        && (r >= 0 || interrupted_errno() === (sys.mac ? 36 : 115))) {
        interrupted_pending = true;
        return -1;
      }
      return r;
    };
  }
  return listener;
}

// One call: an interrupted connect must not be issued again.
function interrupted_check(listener) {
  if (interrupted_calls !== 1) {
    throw new Error("the interrupted connect was issued again");
  }
  interrupted_armed = false;
  return listener;
}

io_eff(CID(Interrupted.port), interrupted_port);
io_eff(CID(Interrupted.arm), interrupted_arm);
io_eff(CID(Interrupted.check), interrupted_check);
