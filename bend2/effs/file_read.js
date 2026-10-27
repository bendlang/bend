// File
// ====

// read(2) answers what is there, not what was asked: a pipe, a terminal
// and a short read all stop before max. Fill the buffer or reach EOF, so
// a caller that asked for n bytes gets n unless the file ends first; a
// line stops after its '\n', read a byte at a time so nothing past it
// leaves the file. An error after some bytes answers them (a pipe has
// already given them up).
function file_read_with(file, max, offset, pack, line = false) {
  const sys = io_sys();
  const len = Math.min(max, 2147483647);
  const b = new Uint8Array(Math.max(len, 1));
  let got = 0;
  do {
    const want = line && got < len ? 1 : len - got;
    const part = b.subarray(got);
    const n = Number(offset === null ? sys.read(file, sys.ptr(part), want)
      : sys.pread(file, sys.ptr(part), want, BigInt(offset) + BigInt(got)));
    if (n < 0 && sys.errno() === 4) {
      continue;
    }
    if (n < 0 && got === 0) {
      return io_tup(file, io_fail(sys.errno()));
    }
    if (n <= 0) {
      break;
    }
    got += n;
  } while (got < len && !(line && b[got - 1] === 10));
  return io_tup(file, io_done(pack(b, got)));
}

function file_read(file, max) {
  return file_read_with(file, max, null, io_text);
}

function file_read_line(file, max) {
  return file_read_with(file, max, null, io_text, true);
}

function file_read_bytes(file, max) {
  return file_read_with(file, max, null, io_list);
}

function file_read_at(file, offset, max) {
  return file_read_with(file, max, offset, io_list);
}

io_eff(CID(File.read), file_read);
io_eff(CID(File.read_line), file_read_line);
io_eff(CID(File.read_bytes), file_read_bytes);
io_eff(CID(File.read_at), file_read_at);
