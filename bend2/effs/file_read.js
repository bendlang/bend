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
  if (typeof offset === "bigint" && offset + BigInt(Math.max(len - 1, 0)) <= 9007199254740991n) {
    offset = Number(offset);
  }
  const wide = typeof offset === "bigint";
  const b = new Uint8Array(Math.max(len, 1));
  let sys;
  let ptr;
  try {
    if (wide && typeof Bun !== "undefined") {
      sys = io_sys();
      ptr = sys.ptr(b);
    }
  } catch (e) {
    return io_tup(file, io_fail(Math.abs(e.errno ?? 5)));
  }
  let got = 0;
  do {
    const want = line && got < len ? 1 : len - got;
    let n;
    let code = 0;
    try {
      if (sys) {
        n = Number(sys.pread(file, ptr + got, want, offset + BigInt(got)));
        if (n < 0) code = sys.errno();
      } else if (wide && want !== 0) {
        n = fs.readSync(file, b, got, want, offset + BigInt(got));
      } else {
        n = fs.readvSync(file, [b.subarray(got, got + want)],
          wide ? 0 : offset === null ? null : offset + got);
      }
    } catch (e) {
      code = Math.abs(e.errno ?? 5);
    }
    // libuv retries EINTR for most calls, but not for read.
    if (code !== 0) {
      if (code === 4) continue;
      if (got === 0) return io_tup(file, io_fail(code));
      break;
    }
    if (n === 0) break;
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

function file_read_at64(file, hi, lo, max, k) {
  if (hi >= 2147483648) return io_tup(file, io_fail(22));
  const offset = (BigInt(hi) << 32n) | BigInt(lo);
  io_park_on(undefined, 0, k,
    () => file_read_with(file, max, offset, io_list), 0);
}

io_eff(CID(File.read), file_read);
io_eff(CID(File.read_line), file_read_line);
io_eff(CID(File.read_bytes), file_read_bytes);
io_eff(CID(File.read_at), file_read_at);
io_eff(CID(File.read_at64), file_read_at64);
