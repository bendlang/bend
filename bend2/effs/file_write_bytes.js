// File
// ====

function file_write_bytes(file, data) {
  const fs = require("fs");
  const fd = file;
  const bytes = [];
  for (let xs = data; xs.$ === "Con"; xs = xs.tail) {
    bytes.push(xs.head);
  }
  if (bytes.some((x) => x > 255)) {
    return io_tup(file, io_fail(22));
  }
  const b = Uint8Array.from(bytes);
  let at = 0;
  try {
    while (at < b.length) {
      at += fs.writeSync(fd, b, at, b.length - at, null);
    }
    return io_tup(file, io_done({ $: "Unit" }));
  } catch (e) {
    return io_tup(file, io_fail(Math.abs(e.errno ?? 5)));
  }
}
