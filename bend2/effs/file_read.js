// File
// ====

// read(2) answers what is there, not what was asked: a pipe, a terminal
// and a short read all stop before max. Fill the buffer or reach EOF, so
// a caller that asked for n bytes gets n unless the file ends first; a
// line stops after its '\n', read a byte at a time so nothing past it
// leaves the file. An error after some bytes answers them (a pipe has
// already given them up). readvSync makes the syscall even for 0 bytes
// (Bun's readSync skips it), so a 0-byte read of a bad handle fails as C
// does, and it needs no bun:ffi, which node lacks.
function file_read_with(file, max, offset, pack, line = false) {
  const fs = require("fs");
  const len = Math.min(max, 2147483647);
  const b = new Uint8Array(Math.max(len, 1));
  let got = 0;
  do {
    const want = line && got < len ? 1 : len - got;
    let n;
    try {
      n = fs.readvSync(file, [b.subarray(got, got + want)],
        offset === null ? null : offset + got);
    } catch (e) {
      // libuv retries EINTR for most calls, but not for read
      if (Math.abs(e.errno) === 4) {
        continue;
      }
      if (got === 0) {
        return io_tup(file, io_fail(Math.abs(e.errno ?? 5)));
      }
      break;
    }
    if (n === 0) {
      break;
    }
    got += n;
  } while (got < len && !(line && b[got - 1] === 10));
  return io_tup(file, io_done(pack(b, got)));
}

function file_read(file, max, k) {
  io_park_on(undefined, 0, k,
    () => file_read_with(file, max, null, io_text), 0);
}

function file_read_line(file, max, k) {
  io_park_on(undefined, 0, k,
    () => file_read_with(file, max, null, io_text, true), 0);
}

function file_read_bytes(file, max, k) {
  io_park_on(undefined, 0, k,
    () => file_read_with(file, max, null, io_list), 0);
}

function file_read_at(file, offset, max, k) {
  io_park_on(undefined, 0, k,
    () => file_read_with(file, max, offset, io_list), 0);
}

io_eff(CID(File.read), file_read);
io_eff(CID(File.read_line), file_read_line);
io_eff(CID(File.read_bytes), file_read_bytes);
io_eff(CID(File.read_at), file_read_at);
