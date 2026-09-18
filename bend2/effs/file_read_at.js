// File
// ====

function file_read_at(file, offset, max) {
  if (max === 0) return io_tup(file, io_done({ $: "Nil" }));
  try {
    const fs = require("fs");
    const len = Math.min(max, 2147483647);
    const b = Buffer.allocUnsafe(len);
    let n;
    for (;;) {
      try {
        n = fs.readSync(file, b, 0, len, Number(offset));
        break;
      } catch (e) {
        if (e.code !== "EINTR") throw e;
      }
    }
    let xs = { $: "Nil" };
    for (let i = n; i > 0; i -= 1) {
      xs = { $: "Con", head: b[i - 1], tail: xs };
    }
    return io_tup(file, io_done(xs));
  } catch (e) {
    return io_tup(file, io_fail(e instanceof RangeError ? 12 : -e.errno));
  }
}
