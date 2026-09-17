// File
// ====

function file_read(file, max) {
  const sys = io_sys();
  const fd = file;
  const len = Math.min(max, 2147483647);
  const b = new Uint8Array(Math.max(len, 1));
  const n = Number(sys.read(fd, sys.ptr(b), len));
  if (n < 0) {
    return io_tup(file, io_fail(sys.errno()));
  }
  return io_tup(file, io_done(io_text(b, n)));
}
