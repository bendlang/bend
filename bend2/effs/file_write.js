// File
// ====

function file_write_buffer(file, b) {
  const fs = require("fs");
  const fd = file;
  let at = 0;
  try {
    while (at < b.length) {
      at += fs.writeSync(fd, b, at, b.length - at, null);
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
  const bytes = [];
  for (let xs = data; xs.$ === CID(Con); xs = xs.tail) {
    bytes.push(xs.head);
  }
  if (bytes.some((x) => x > 255)) {
    return io_tup(file, io_fail(22));
  }
  return file_write_buffer(file, Uint8Array.from(bytes));
}

io_eff(CID(File.write), file_write);
io_eff(CID(File.write_bytes), file_write_bytes);
