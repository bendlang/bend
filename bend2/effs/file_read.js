// File
// ====

function file_read_with(file, max, offset, pack) {
  const sys = io_sys();
  const len = Math.min(max, 2147483647);
  const b = new Uint8Array(Math.max(len, 1));
  const n = Number(offset === null ? sys.read(file, sys.ptr(b), len)
    : sys.pread(file, sys.ptr(b), len, BigInt(offset)));
  return io_tup(file, n < 0 ? io_fail(sys.errno()) : io_done(pack(b, n)));
}

function file_read(file, max) {
  return file_read_with(file, max, null, io_text);
}

function file_read_bytes(file, max) {
  return file_read_with(file, max, null, io_list);
}

function file_read_at(file, offset, max) {
  return file_read_with(file, max, offset, io_list);
}

io_eff(CID(File.read), file_read);
io_eff(CID(File.read_bytes), file_read_bytes);
io_eff(CID(File.read_at), file_read_at);

function file_read_into(file, offset, max, a, at) {
  const sys = io_sys();
  const len = Math.max(0, Math.min(max, (a.length - at) * 4));
  const b = new Uint8Array(Math.max(len, 1));
  const n = Number(sys.pread(file, sys.ptr(b), len, BigInt(offset)));
  if (n < 0) {
    return io_tup(file, io_tup(a, io_fail(sys.errno())));
  }
  // A tail of under four bytes overwrites only its slot's low bytes, as the
  // C pread does in place.
  for (let i = 0; i < n; i += 1) {
    const s = at + (i >> 2);
    const k = (i & 3) * 8;
    a[s] = ((a[s] & ~(0xff << k)) | (b[i] << k)) >>> 0;
  }
  return io_tup(file, io_tup(a, io_done(n)));
}

io_eff(CID(File.read_into), file_read_into);
