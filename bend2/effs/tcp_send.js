// TCP
// ===

// Sends what is left; a full socket (non-blocking, so EAGAIN) parks the
// computation until the socket is writable, or, for try_, until its
// deadline at, then answers Wait{rest}. A failure answers
// Fail{(error, rest)}. rest, what the kernel did not take, is a String
// (io_text) or a List of bytes (io_list), as make builds it. at is
// undefined for the blocking twins.
function tcp_send_with(socket, b, k, make, at) {
  const ready = (r) => at === undefined ? r : { $: CID(Ready), value: r };
  const sys = io_sys();
  const fd = socket;
  const again = sys.mac ? 35 : 11;
  const go = (off) => {
    while (off < b.length) {
      const part = b.subarray(off);
      const n = Number(sys.send(fd, sys.ptr(part), part.length, 0));
      if (n < 0) {
        const code = sys.errno();
        if (code !== again) {
          const fail = io_fail(code);
          fail.error = io_tup(fail.error, make(part, part.length));
          return io_tup(socket, ready(fail));
        }
        if (at !== undefined && performance.now() >= at) {
          return io_tup(socket, { $: CID(Wait), rest: make(part, part.length) });
        }
        io_park_on(fd, true, k, () => go(off), at);
        return undefined;
      }
      off += n;
    }
    return io_tup(socket, ready(io_done({ $: CID(Unit) })));
  };
  return go(0);
}

// A value past 255 fails with EINVAL before any byte is sent, and the
// list comes back whole.
function tcp_send_bytes_with(socket, data, k, at) {
  const b = io_unlist(data);
  if (b !== null) {
    return tcp_send_with(socket, b, k, io_list, at);
  }
  const fail = io_fail(22);
  fail.error = io_tup(fail.error, data);
  return io_tup(socket, at === undefined ? fail : { $: CID(Ready), value: fail });
}

function tcp_send(socket, data, k) {
  return tcp_send_with(socket, io_bytes(data), k, io_text);
}

function tcp_send_bytes(socket, data, k) {
  return tcp_send_bytes_with(socket, data, k);
}

function tcp_try_send(socket, data, ms, k) {
  return tcp_send_with(socket, io_bytes(data), k, io_text,
    performance.now() + Number(ms));
}

function tcp_try_send_bytes(socket, data, ms, k) {
  return tcp_send_bytes_with(socket, data, k, performance.now() + Number(ms));
}

io_eff(CID(TCP.send), tcp_send);
io_eff(CID(TCP.send_bytes), tcp_send_bytes);
io_eff(CID(TCP.try_send), tcp_try_send);
io_eff(CID(TCP.try_send_bytes), tcp_try_send_bytes);
