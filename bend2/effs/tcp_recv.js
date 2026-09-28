// TCP
// ===

// The loop parked the request until the socket was readable; a recv that
// still finds nothing (the socket is non-blocking) parks again. What it
// finds, read makes a String (io_text) or a List of bytes (io_list).
function tcp_recv_with(socket, max, k, read) {
  const sys = io_sys();
  const fd = socket;
  const b = new Uint8Array(Math.max(Number(max), 1));
  const again = sys.mac ? 35 : 11;
  const go = () => {
    const n = Number(sys.recv(fd, sys.ptr(b), Number(max), 0));
    if (n < 0) {
      const code = sys.errno();
      if (code === again) {
        io_park_on(fd, false, k, go);
        return undefined;
      }
      return io_tup(socket, io_fail(code));
    }
    return io_tup(socket, io_done(read(b, n)));
  };
  return go();
}

function tcp_recv(socket, max, k) {
  return tcp_recv_with(socket, max, k, io_text);
}

function tcp_recv_bytes(socket, max, k) {
  return tcp_recv_with(socket, max, k, io_list);
}

function tcp_recv_need() {
  return { read: true };
}

io_eff(CID(TCP.recv), tcp_recv, tcp_recv_need);
io_eff(CID(TCP.recv_bytes), tcp_recv_bytes, tcp_recv_need);
