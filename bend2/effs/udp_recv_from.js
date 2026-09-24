// UDP
// ===

// The loop parked the request until the socket was readable; a recv that
// still finds no datagram (the socket is non-blocking) parks again.
function udp_recv_from(socket, max, k) {
  const sys = io_sys();
  const fd = socket;
  const b = new Uint8Array(Math.max(Number(max), 1));
  const peer = new Uint8Array(16);
  const len = new Uint32Array([16]);
  const go = () => {
    const got = sys.recvfrom(fd, sys.ptr(b), Number(max), 0, sys.ptr(peer),
      sys.ptr(len));
    const n = Number(got);
    if (n < 0) {
      const code = sys.errno();
      if (code === (sys.mac ? 35 : 11)) {
        io_park_on(fd, false, k, go);
        return undefined;
      }
      return io_tup(socket, io_fail(code));
    }
    const host = peer[4] + "." + peer[5] + "." + peer[6] + "." + peer[7];
    const port = (peer[2] << 8) | peer[3];
    return io_tup(socket, io_done(io_tup(host, port, io_text(b, n))));
  };
  return go();
}

function udp_recv_from_need() {
  return { read: true };
}

io_eff(CID(UDP.recv_from), udp_recv_from, udp_recv_from_need);
