// TCP
// ===

// TCP.poll(sock, max, ms) is recv with a deadline: a recv that finds
// nothing parks on the socket and on the clock, whichever fires first;
// past the deadline it answers None{}, else Some{data} ("" is the peer's
// close, as TCP.recv answers it).
function tcp_poll(socket, max, ms, k) {
  const sys = io_sys();
  const fd = socket;
  const b = new Uint8Array(Math.max(Number(max), 1));
  const at = performance.now() + Number(ms);
  const go = () => {
    const n = Number(sys.recv(fd, sys.ptr(b), Number(max), 0));
    if (n >= 0) {
      return io_tup(socket, io_done({ $: CID(Some), value: io_text(b, n) }));
    }
    const code = sys.errno();
    if (code !== (sys.mac ? 35 : 11)) {
      return io_tup(socket, io_fail(code));
    }
    if (performance.now() >= at) {
      return io_tup(socket, io_done({ $: CID(None) }));
    }
    io_park_on(fd, false, k, go, at);
    return undefined;
  };
  return go();
}

io_eff(CID(TCP.poll), tcp_poll);
