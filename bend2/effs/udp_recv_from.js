// UDP
// ===

// The request parks until the socket is readable, so a backlog never keeps
// the loop from its timers; a recv that still finds no datagram (the socket
// is non-blocking) parks again, or, for try_, until its deadline at, then
// answers Wait{}. at is undefined for the blocking twin.
function udp_recv_from_with(socket, max, k, at) {
  const ready = (r) => at === undefined ? r : { $: CID(Ready), value: r };
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
      if (code !== (sys.mac ? 35 : 11)) {
        return io_tup(socket, ready(io_fail(code)));
      }
      if (at !== undefined && performance.now() >= at) {
        return io_tup(socket, { $: CID(Wait), rest: { $: CID(Unit) } });
      }
      io_park_on(fd, false, k, go, at);
      return undefined;
    }
    const host = peer[4] + "." + peer[5] + "." + peer[6] + "." + peer[7];
    const port = (peer[2] << 8) | peer[3];
    return io_tup(socket, ready(io_done(io_tup(host, port, io_text(b, n)))));
  };
  io_park_on(fd, false, k, go, at);
  return undefined;
}

function udp_recv_from(socket, max, k) {
  return udp_recv_from_with(socket, max, k);
}

function udp_try_recv_from(socket, max, ms, k) {
  return udp_recv_from_with(socket, max, k, performance.now() + Number(ms));
}

io_eff(CID(UDP.recv_from), udp_recv_from);
io_eff(CID(UDP.try_recv_from), udp_try_recv_from);
