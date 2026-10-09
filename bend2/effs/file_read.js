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

// Slot at + i/4 takes bytes i..i+3 little-endian; a last partial slot
// keeps its high bytes, as the C block does. It reads in bounded chunks,
// so a large array with a small file allocates only what it reads.
function file_read_byte(a, at, i, x) {
  const s = at + (i >>> 2), k = (i & 3) * 8;
  a[s] = ((a[s] & ~(0xff << k)) | (x << k)) >>> 0;
}

function file_read_into(file, offset, max, a, at) {
  const sys = io_sys();
  const len = Math.max(0, Math.min(max, (a.length - at) * 4));
  const b = new Uint8Array(Math.max(Math.min(len, 1 << 24), 1));
  let got = 0;
  while (got < len) {
    const n = Number(sys.pread(file, sys.ptr(b), Math.min(len - got, b.length),
      BigInt(offset + got)));
    if (n < 0) {
      return io_tup(file, io_tup(a, io_fail(sys.errno())));
    }
    let i = 0;
    for (; i < n && ((got + i) & 3) !== 0; i += 1) {
      file_read_byte(a, at, got + i, b[i]);
    }
    for (; i + 4 <= n; i += 4) {
      a[at + ((got + i) >>> 2)] =
        (b[i] | (b[i + 1] << 8) | (b[i + 2] << 16) | (b[i + 3] << 24)) >>> 0;
    }
    for (; i < n; i += 1) {
      file_read_byte(a, at, got + i, b[i]);
    }
    if (n === 0) {
      break;
    }
    got += n;
  }
  return io_tup(file, io_tup(a, io_done(got)));
}

io_eff(CID(File.read_into), file_read_into);
