// UDP
// ===

// A datagram goes whole or not at all; a full send buffer (non-blocking,
// so EAGAIN) parks the computation until the socket is writable, or, for
// try_, until its deadline at, then answers Wait{data}. A failure answers
// Fail{(error, data)}: the datagram comes back either way. at is
// undefined for the blocking twin.
function udp_send_to_with(socket, host, port, data, k, at) {
  const ready = (r) => at === undefined ? r : { $: CID(Ready), value: r };
  const fail = (code) => {
    const r = io_fail(code);
    r.error = io_tup(r.error, data);
    return io_tup(socket, ready(r));
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
      if (at !== undefined && performance.now() >= at) {
        return io_tup(socket, { $: CID(Wait), rest: data });
      }
      io_park_on(fd, true, k, go, at);
      return undefined;
    }
    return io_tup(socket, ready(io_done({ $: CID(Unit) })));
  };
  return go();
}

function udp_send_to(socket, host, port, data, k) {
  return udp_send_to_with(socket, host, port, data, k);
}

function udp_try_send_to(socket, host, port, data, ms, k) {
  return udp_send_to_with(socket, host, port, data, k,
    performance.now() + Number(ms));
}

io_eff(CID(UDP.send_to), udp_send_to);
io_eff(CID(UDP.try_send_to), udp_try_send_to);
