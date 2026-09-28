// UDP
// ===

function udp_poll(socket, max) {
  const sys = io_sys();
  const fd = socket;
  const b = new Uint8Array(Math.max(Number(max), 1));
  const peer = new Uint8Array(16);
  const len = new Uint32Array([16]);
  const got = sys.recvfrom(fd, sys.ptr(b), Number(max), 0, sys.ptr(peer),
    sys.ptr(len));
  const n = Number(got);
  if (n < 0 && sys.errno() === (sys.mac ? 35 : 11)) {
    return io_tup(socket, io_done({ $: CID(None) }));
  }
  if (n < 0) {
    return io_tup(socket, io_fail(sys.errno()));
  }
  const host = peer[4] + "." + peer[5] + "." + peer[6] + "." + peer[7];
  const port = (peer[2] << 8) | peer[3];
  return io_tup(socket, io_done({ $: CID(Some),
    value: io_tup(host, port, io_text(b, n)) }));
}

io_eff(CID(UDP.poll), udp_poll);
