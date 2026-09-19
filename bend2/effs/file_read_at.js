// File
// ====

function file_read_at(file, offset, max) {
  const sys = io_sys();
  const fd = file;
  const len = Math.min(max, 2147483647);
  const b = new Uint8Array(Math.max(len, 1));
  const n = Number(sys.pread(fd, sys.ptr(b), len, BigInt(offset)));
  if (n < 0) {
    return io_tup(file, io_fail(sys.errno()));
  }
  let xs = { $: "Nil" };
  for (let i = n; i > 0; i -= 1) {
    xs = { $: "Con", head: b[i - 1], tail: xs };
  }
  return io_tup(file, io_done(xs));
}
