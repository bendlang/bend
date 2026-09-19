// TCP
// ===

// See tcp_recv_text_go.c: carried bytes first, a cut scalar carried out,
// a recv of 0 bytes replaces the carry and answers need 4, and a recv that
// only feeds the carry parks again.
function tcp_recv_text_go(socket, pend, need, max, k) {
  const sys = io_sys();
  const fd = socket;
  const len = Math.min(Number(max), 2147483647);
  const b = new Uint8Array(len + 4);
  const again = sys.mac ? 35 : 11;
  let had = need < 4 ? Number(need) : 0;
  for (let m = 0; m < had; m += 1) {
    b[m] = (Number(pend) >>> (8 * m)) & 255;
  }
  const go = () => {
    const got = Number(sys.recv(fd, sys.ptr(b, had), len, 0));
    if (got < 0) {
      const code = sys.errno();
      if (code === again) {
        io_park_on(fd, false, k, go);
        return undefined;
      }
      return io_tup(socket, io_fail(code));
    }
    const eof = got === 0 && len !== 0;
    const n = had + got;
    let cut = 0, out = 0;
    for (let j = 1; !eof && j <= 3 && j <= n; j += 1) {
      const h = b[n - j];
      if ((h & 0xc0) !== 0x80) {
        const w = h >= 0xc2 && h <= 0xdf ? 2 : h >= 0xe0 && h <= 0xef ? 3
          : h >= 0xf0 && h <= 0xf4 ? 4 : 0;
        cut = w > j ? j : 0;
        break;
      }
    }
    if (got > 0 && cut === n) {
      had = n;
      io_park_on(fd, false, k, go);
      return undefined;
    }
    for (let m = 0; m < cut; m += 1) {
      out |= b[n - cut + m] << (8 * m);
    }
    return io_tup(socket, io_done(io_tup(out, eof ? 4 : cut, io_text(b, n - cut))));
  };
  return go();
}

function tcp_recv_text_go_need() {
  return { read: true };
}
