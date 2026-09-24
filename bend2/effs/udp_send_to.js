// UDP
// ===

// A datagram goes whole or not at all; a full send buffer (non-blocking,
// so EAGAIN) parks the computation until the socket is writable.
function udp_send_to(socket, host, port, data, k) {
  const sys = io_sys();
  const fd = socket;
  const at = io_addr(host, Number(port));
  if (at === null) {
    return io_tup(socket, io_fail(22));
  }
  const b = io_bytes(data);
  const go = () => {
    const sent = sys.sendto(fd, sys.ptr(b), b.length, 0, sys.ptr(at), 16);
    if (Number(sent) < 0) {
      const code = sys.errno();
      if (code === (sys.mac ? 35 : 11)) {
        io_park_on(fd, true, k, go);
        return undefined;
      }
      return io_tup(socket, io_fail(code));
    }
    return io_tup(socket, io_done({ $: CID(Unit) }));
  };
  return go();
}

io_eff(CID(UDP.send_to), udp_send_to);
