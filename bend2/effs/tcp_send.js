// TCP
// ===

// Sends what is left; a full socket (non-blocking, so EAGAIN) parks the
// computation until the socket is writable, and the loop resumes here.
function tcp_send(socket, data, k) {
  const sys = io_sys();
  const fd = socket;
  const b = io_bytes(data);
  const again = sys.mac ? 35 : 11;
  const go = (at) => {
    while (at < b.length) {
      const part = b.subarray(at);
      const n = Number(sys.send(fd, sys.ptr(part), part.length, 0));
      if (n < 0) {
        const code = sys.errno();
        if (code === again) {
          io_park_on(fd, true, k, () => go(at));
          return undefined;
        }
        return io_tup(socket, io_fail(code));
      }
      at += n;
    }
    return io_tup(socket, io_done({ $: CID(Unit) }));
  };
  return go(0);
}

io_eff(CID(TCP.send), tcp_send);
