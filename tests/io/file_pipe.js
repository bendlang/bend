function pipe_open() {
  const ffi = require("bun:ffi");
  const lib = ffi.dlopen(process.platform === "darwin" ? "libSystem.dylib" : "libc.so.6",
    { pipe: { args: ["ptr"], returns: "i32" } });
  const fd = new Int32Array(2);
  const n = lib.symbols.pipe(ffi.ptr(fd));
  const code = n < 0 ? io_sys().errno() : 0;
  lib.close();
  if (n < 0) return io_fail(code);
  const fs = require("fs");
  try {
    fs.writeSync(fd[1], "abc");
    return io_done(fd[0]);
  } catch (e) {
    fs.closeSync(fd[0]);
    return io_fail(-e.errno);
  } finally {
    fs.closeSync(fd[1]);
  }
}
