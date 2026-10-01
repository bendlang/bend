// UDP
// ===

// A datagram goes whole or not at all; a full send buffer (non-blocking,
// so EAGAIN) parks the computation until the socket is writable.
function udp_send_to_with(socket, host, port, data, k, at) {
  const fail = (code) => {
    const r = io_fail(code);
    r.error = io_tup(r.error, data);
    return io_tup(socket, io_ready(at, r));
  };
  const sys = io_sys();
  const fd = socket;
  const to = io_addr(host, Number(port));
  if (to === null) {
    return fail(22);
  }
  const b = io_bytes(data);
  const go = () => {
    const sent = sys.sendto(fd, b.length ? sys.ptr(b) : null, b.length, 0, sys.ptr(to), 16);
    if (Number(sent) < 0) {
      const code = sys.errno();
      if (code !== (sys.mac ? 35 : 11)) {
        return fail(code);
      }
      if (io_late(at)) {
        return io_tup(socket, { $: CID(Wait), rest: data });
      }
      io_park_on(fd, true, k, go, at);
      return undefined;
    }
    return io_tup(socket, io_ready(at, io_done({ $: CID(Unit) })));
  };
  return go();
}

function udp_send_to(socket, host, port, data, k) {
  return udp_send_to_with(socket, host, port, data, k);
}

// try_ passes a deadline at: past it, a send that would wait is Wait{data}.
function udp_try_send_to(socket, host, port, data, ms, k) {
  return udp_send_to_with(socket, host, port, data, k, io_until(ms));
}

io_eff(CID(UDP.send_to), udp_send_to);
io_eff(CID(UDP.try_send_to), udp_try_send_to);
