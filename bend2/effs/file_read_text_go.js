// File
// ====

// See file_read_text_go.c: carried bytes first, a cut scalar carried out,
// a read of 0 bytes replaces the carry and answers need 4.
function file_read_text_go_dec(b, n, eof) {
  let cut = 0, pend = 0;
  for (let j = 1; !eof && j <= 3 && j <= n; j += 1) {
    const h = b[n - j];
    if ((h & 0xc0) !== 0x80) {
      const k = h >= 0xc2 && h <= 0xdf ? 2 : h >= 0xe0 && h <= 0xef ? 3
        : h >= 0xf0 && h <= 0xf4 ? 4 : 0;
      cut = k > j ? j : 0;
      break;
    }
  }
  for (let m = 0; m < cut; m += 1) {
    pend |= b[n - cut + m] << (8 * m);
  }
  return io_tup(pend, eof ? 4 : cut, io_text(b, n - cut));
}

function file_read_text_go(file, pend, need, max) {
  const sys = io_sys();
  const fd = file;
  const len = Math.min(max, 2147483647);
  const had = need < 4 ? need : 0;
  const b = new Uint8Array(len + 4);
  for (let m = 0; m < had; m += 1) {
    b[m] = (pend >>> (8 * m)) & 255;
  }
  const got = Number(sys.read(fd, sys.ptr(b, had), len));
  if (got < 0) {
    return io_tup(file, io_fail(sys.errno()));
  }
  return io_tup(file, io_done(file_read_text_go_dec(b, had + got, got === 0 && len !== 0)));
}
