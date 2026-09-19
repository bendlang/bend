// TCP
// ===

// TCP.poll(sock, max, ms) is recv with a deadline: None{} when nothing
// waits (ms = 0: at once) or when nothing arrives within ms, else
// Some{data} ("" is the peer's close, as TCP.recv answers it). The park
// carries the deadline, so the loop wakes it for data or for the clock,
// whichever comes first; a wake that still finds nothing parks again.
function tcp_poll(socket, max, ms, k) {
  const sys = io_sys();
  const fd = socket;
  const b = new Uint8Array(Math.max(Number(max), 1));
  const again = sys.mac ? 35 : 11;
  const at = performance.now() + Number(ms);
  const go = () => {
    const n = Number(sys.recv(fd, sys.ptr(b), Number(max), 0));
    if (n < 0) {
      const code = sys.errno();
      if (code !== again) {
        return io_tup(socket, io_fail(code));
      }
      if (Number(ms) === 0 || performance.now() >= at) {
        return io_tup(socket, io_done({ $: "None" }));
      }
      io_park_on(fd, false, k, go, at);
      return undefined;
    }
    return io_tup(socket, io_done({ $: "Some", value: io_text(b, n) }));
  };
  return go();
}
