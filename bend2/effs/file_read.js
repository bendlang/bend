// File
// ====

// read(2) answers what is there, not what was asked: a pipe, a terminal
// and a short read all stop before max. Fill the buffer or reach EOF, so
// a caller that asked for n bytes gets n unless the file ends first; a
// line stops after its '\n', read a byte at a time so nothing past it
// leaves the file. An error after some bytes answers them (a pipe has
// already given them up). Bun's readSync skips the syscall for 0 bytes,
// so a 0-byte read goes through readvSync and fails on a bad handle as C
// does; neither needs bun:ffi, which node lacks.
// A regular file's size is a hint, not a bound on the bytes left (#1983).
// The hint leaves one extra byte for the EOF check. A line starts at 64 KiB.
const FILE_READ_INITIAL = 256 * 1024 + 1;

function file_read_room(fs, file, len, line, offset) {
  let room = 65536;
  try {
    // A cap within room already determines the buffer size.
    const st = line || len <= room ? null : fs.fstatSync(file);
    if (st?.isFile()) {
      room = Math.max(room, st.size - (offset ?? 0) + 1);
    }
  } catch {}
  return Math.max(Math.min(len, room), 1);
}

function file_read_with(file, max, offset, pack, line = false) {
  const fs = require("fs");
  const len = Math.min(max, 2147483647);
  const room = file_read_room(fs, file, len, line, offset);
  // A sequential read may already be near EOF. Probe large hints first,
  // keeping the prefix small so a full read has little to copy on growth.
  const initial = offset === null && room > FILE_READ_INITIAL
    ? Math.min(FILE_READ_INITIAL, Math.ceil(room / 16)) : room;
  let b = new Uint8Array(initial);
  let got = 0;
  do {
    if (got === b.length) {
      const c = new Uint8Array(room > b.length ? room : Math.min(len, b.length * 2));
      c.set(b);
      b = c;
    }
    const want = line && got < len ? 1 : Math.min(b.length, len) - got;
    let n;
    try {
      const at = offset === null ? null : offset + got;
      n = want === 0 ? fs.readvSync(file, [b.subarray(0, 0)], at)
        : fs.readSync(file, b, got, want, at);
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
