// File
// ====

function file_size(file) {
  const fs = require("fs");
  try {
    const size = fs.fstatSync(file).size;
    const over = io_sys().mac ? 84 : 75;
    return io_tup(file, size > 4294967295 ? io_fail(over) : io_done(size));
  } catch (e) {
    return io_tup(file, io_fail(Math.abs(e.errno ?? 5)));
  }
}
