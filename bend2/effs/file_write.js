// File
// ====

function file_write_buffer(file, b, offset = null) {
  const fs = require("fs");
  let at = 0;
  try {
    while (at < b.length) {
      const n = fs.writeSync(file, b, at, b.length - at,
        offset === null ? null : offset + at);
      // no progress would retry forever (#1445)
      if (n === 0) {
        return io_tup(file, io_fail(5));
      }
      at += n;
    }
    return io_tup(file, io_done({ $: CID(Unit) }));
  } catch (e) {
    return io_tup(file, io_fail(Math.abs(e.errno ?? 5)));
  }
}

function file_write(file, data, k) {
  io_park_on(undefined, 0, k, () => file_write_buffer(file, io_bytes(data)), 0);
}

function file_write_bytes(file, data, k) {
  const b = io_unlist(data);
  if (b === null) {
    return io_tup(file, io_fail(22));
  }
  io_park_on(undefined, 0, k, () => file_write_buffer(file, b), 0);
}

// An fd can append without File.open's "a" (a shell's >> on stdout), so ask
// the fd, as C does, after the handles File.open made with "a". A host
// without bun:ffi (node) can't ask, and knows only those.
function file_appends(file) {
  if (io_file_append.has(file)) {
    return true;
  }
  try {
    const sys = io_sys();
    const flags = sys.fcntl(file, 3, 0);
    return flags >= 0 && (flags & (sys.mac ? 8 : 0x400)) !== 0;
  } catch (_) {
    return false;
  }
}

function file_write_at(file, offset, data, k) {
  const b = io_unlist(data);
  if (b === null || file_appends(file)) {
    return io_tup(file, io_fail(22));
  }
  io_park_on(undefined, 0, k, () => file_write_buffer(file, b, offset), 0);
}

io_eff(CID(File.write_at), file_write_at);
io_eff(CID(File.write), file_write);
io_eff(CID(File.write_bytes), file_write_bytes);
