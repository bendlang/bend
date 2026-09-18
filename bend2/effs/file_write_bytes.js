// File
// ====

function file_write_bytes(file, data) {
  try {
    let len = 0;
    for (let xs = data; xs.$ === "Con"; xs = xs.tail) {
      if (xs.head > 255) return io_tup(file, io_fail(22));
      len += 1;
    }
    const b = Buffer.allocUnsafe(len);
    let i = 0;
    for (let xs = data; xs.$ === "Con"; xs = xs.tail) b[i++] = xs.head;
    const fs = require("fs");
    for (let at = 0; at < len;) {
      try {
        const n = fs.writeSync(file, b, at, Math.min(len - at, 2147483647), null);
        if (n === 0) return io_tup(file, io_fail(5));
        at += n;
      } catch (e) {
        if (e.code !== "EINTR") throw e;
      }
    }
    return io_tup(file, io_done({ $: "Unit" }));
  } catch (e) {
    return io_tup(file, io_fail(e instanceof RangeError ? 12 : -e.errno));
  }
}
