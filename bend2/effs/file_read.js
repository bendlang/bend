// File
// ====

// read(2) answers what is there, not what was asked: a pipe, a terminal
// and a short read all stop before max. Fill the buffer or reach EOF, so
// a caller that asked for n bytes gets n unless the file ends first; a
// line stops after '\n'. Read ahead only for read-only regular files:
// Node has no seek to undo prefetch before a write on a writable handle.
// Pipes still read a byte at a time, so closing can't swallow later lines.
// An error after some bytes returns those bytes. Bun skips 0-byte readSync,
// so a 0-byte read goes through readvSync and fails on a bad handle as C
// does; neither needs bun:ffi, which node lacks.
// max is a cap, not a size: the buffer starts at what a regular file holds
// past the given offset (one byte more, to see its end) or 64 KiB. It doubles
// up to max as bytes arrive, so a read capped far above the available data
// commits only what it reads (#1983). A line starts at 64 KiB whatever the file.
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

function file_read_line_buffer(fs, file) {
  try {
    if (fs.fstatSync(file).isFile()) {
      const ahead = { data: Buffer.allocUnsafe(16384), head: 0, tail: 0 };
      io_file_lines.set(file, ahead);
      return ahead;
    }
  } catch {}
  io_file_lines.delete(file);
}

function file_read_grow(b, len) {
  const next = new Uint8Array(Math.min(len, b.length * 2));
  next.set(b);
  return next;
}

function file_read_with(file, max, offset, pack, line = false) {
  const fs = require("fs");
  const len = Math.min(max, 2147483647);
  let ahead = offset === null && len !== 0 ? io_file_lines?.get(file) : undefined;
  if (line && ahead === null) ahead = file_read_line_buffer(fs, file);
  let b = line && ahead ? null : new Uint8Array(file_read_room(fs, file, len, line, offset));
  let got = 0;
  let eol;
  do {
    eol = false;
    let n;
    try {
      if (ahead && (line || ahead.head < ahead.tail)) {
        if (ahead.head === ahead.tail) {
          ahead.tail = fs.readSync(file, ahead.data, 0, ahead.data.length, null);
          ahead.head = 0;
        }
        const from = ahead.head;
        n = Math.min(len - got, ahead.tail - from);
        if (line && n > 0) {
          const nl = ahead.data.subarray(from, from + n).indexOf(10);
          if (nl >= 0) {
            n = nl + 1;
            eol = true;
          }
        }
        ahead.head += n;
        if (line && got === 0 && (eol || n === 0 || n === len)) {
          return io_tup(file, io_done(io_text(ahead.data, n, from)));
        }
        b ??= new Uint8Array(file_read_room(fs, file, len, line, offset));
        while (got + n > b.length) b = file_read_grow(b, len);
        b.set(ahead.data.subarray(from, from + n), got);
      } else {
        if (got === b.length) b = file_read_grow(b, len);
        const want = line && got < len ? 1 : Math.min(b.length, len) - got;
        const at = offset === null ? null : offset + got;
        n = want === 0 ? fs.readvSync(file, [b.subarray(0, 0)], at)
          : fs.readSync(file, b, got, want, at);
        eol = line && n !== 0 && b[got + n - 1] === 10;
      }
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
  } while (got < len && !eol);
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
