// TCP
// ===

// The loop parked the request until the socket was readable; a recv that
// still finds nothing (the socket is non-blocking) parks again.
function tcp_recv(socket, max, k) {
  const sys = io_sys();
  const fd = socket;
  const len = Math.min(Math.max(Number(max), 1), 2147483647);
  const b = new Uint8Array(len);
  const again = sys.mac ? 35 : 11;
  const go = () => {
    const n = Number(sys.recv(fd, sys.ptr(b), len, 0));
    if (n < 0) {
      const code = sys.errno();
      if (code === again) {
        io_park_on(fd, false, k, go);
        return undefined;
      }
      return io_tup(socket, io_fail(code));
    }
    return io_tup(socket, io_done(io_text(b, n)));
  };
  return go();
}

function tcp_recv_need() {
  return { read: true };
}
