// TCP
// ===

// Sends what is left; a full socket (non-blocking, so EAGAIN) parks the
// computation until the socket is writable, and the loop resumes here.
function tcp_send_buffer(socket, b, k) {
  const sys = io_sys();
  const fd = socket;
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

function tcp_send(socket, data, k) {
  return tcp_send_buffer(socket, io_bytes(data), k);
}

function tcp_send_bytes(socket, data, k) {
  const bytes = io_clist(data);
  return bytes === null
    ? io_tup(socket, io_fail(22))
    : tcp_send_buffer(socket, bytes, k);
}

io_eff(CID(TCP.send), tcp_send);
io_eff(CID(TCP.send_bytes), tcp_send_bytes);
