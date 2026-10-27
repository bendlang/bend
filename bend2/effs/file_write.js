// File
// ====

function file_write_buffer(file, b, offset = null) {
  const fs = require("fs");
  // the file may be stdout, so what IO.print holds goes first
  io_sync();
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

function file_write(file, data) {
  return file_write_buffer(file, io_bytes(data));
}

function file_write_bytes(file, data) {
  const b = io_unlist(data);
  return b === null ? io_tup(file, io_fail(22)) : file_write_buffer(file, b);
}

function file_write_at(file, offset, data) {
  const b = io_unlist(data);
  return b === null || io_file_append.has(file)
    ? io_tup(file, io_fail(22)) : file_write_buffer(file, b, offset);
}

io_eff(CID(File.write_at), file_write_at);
io_eff(CID(File.write), file_write);
io_eff(CID(File.write_bytes), file_write_bytes);
