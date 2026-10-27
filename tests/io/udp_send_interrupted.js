let interrupted_stage;
let interrupted_restore;

function interrupted_arm(socket) {
  const sys = io_sys();
  const ffi = require("bun:ffi");
  const lib = ffi.dlopen(sys.mac ? "libSystem.dylib" : "libc.so.6", {
    getsockname: { args: ["i32", "ptr", "ptr"], returns: "i32" },
  });
  const addr = new Uint8Array(16);
  const len = new Uint32Array([16]);
  const got = lib.symbols.getsockname(socket, sys.ptr(addr), sys.ptr(len));
  lib.close();
  if (got < 0) {
    throw new Error("getsockname failed");
  }
  const send = sys.sendto;
  const error = sys.errno;
  let pending = false;
  interrupted_stage = 0;
  interrupted_restore = () => { sys.sendto = send; sys.errno = error; };
  sys.errno = () => pending ? 4 : error();
  sys.sendto = (fd, ...args) => {
    pending = false;
    if (fd === socket && interrupted_stage++ < 2) {
      pending = true;
      return -1;
    }
    return send(fd, ...args);
  };
  return io_tup(socket, (addr[2] << 8) | addr[3]);
}

function interrupted_check(socket) {
  interrupted_restore();
  const sys = io_sys();
  const set = new Uint8Array((socket >> 6 << 3) + 8);
  set[socket >> 3] |= 1 << (socket & 7);
  const tv = new BigInt64Array([1n, 0n]);
  const data = new Uint8Array(64);
  const want = [97, 195, 169, 206, 187, 122];
  if (interrupted_stage !== 3
    || sys.select(socket + 1, sys.ptr(set), null, null, sys.ptr(tv)) !== 1
    || Number(sys.recv(socket, sys.ptr(data), data.length, 0)) !== want.length
    || want.some((x, i) => data[i] !== x)) {
    throw new Error("the interrupted datagram was not sent exactly once");
  }
  return socket;
}

io_eff(CID(Interrupted.arm), interrupted_arm);
io_eff(CID(Interrupted.check), interrupted_check);
