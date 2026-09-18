// File
// ====

function file_size(file) {
  for (;;) {
    try {
      const size = require("fs").fstatSync(file, { bigint: true }).size;
      if (size < 0n || size >= (1n << 48n)) {
        return io_tup(file, io_fail(process.platform === "darwin" ? 84 : 75));
      }
      return io_tup(file, io_done(size));
    } catch (e) {
      if (e.code !== "EINTR") return io_tup(file, io_fail(-e.errno));
    }
  }
}
