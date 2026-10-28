// File
// ====

function file_size_now(file, wide = false) {
  const fs = require("fs");
  try {
    const size = fs.fstatSync(file, wide ? { bigint: true } : undefined).size;
    // the EOVERFLOW errno, 84 on mac and 75 elsewhere. io_sys().mac reads
    // the same platform, but io_sys() binds libc through bun:ffi, and on a
    // host without it that ask threw where the size was already read, so
    // the catch answered Fail on a good file. Nothing above this line
    // touches the FFI table, and nothing below it should either.
    const over = process.platform === "darwin" ? 84 : 75;
    if (wide) {
      return io_tup(file, size < 0n ? io_fail(over)
        : io_done(io_tup(Number(size >> 32n), Number(size & 4294967295n))));
    }
    return io_tup(file, size > 4294967295 ? io_fail(over) : io_done(size));
  } catch (e) {
    return io_tup(file, io_fail(Math.abs(e.errno ?? 5)));
  }
}

function file_size(file, k) {
  io_park_on(undefined, 0, k, () => file_size_now(file), 0);
}

function file_size64(file, k) {
  io_park_on(undefined, 0, k, () => file_size_now(file, true), 0);
}

io_eff(CID(File.size), file_size);
io_eff(CID(File.size64), file_size64);
