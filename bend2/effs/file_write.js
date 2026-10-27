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

function file_write_at(file, offset, data) {
  const b = io_unlist(data);
  return b === null || io_file_append.has(file)
    ? io_tup(file, io_fail(22)) : file_write_buffer(file, b, offset);
}

io_eff(CID(File.write_at), file_write_at);
io_eff(CID(File.write), file_write);
io_eff(CID(File.write_bytes), file_write_bytes);
