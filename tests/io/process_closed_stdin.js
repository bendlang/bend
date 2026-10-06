function shut_stdin() {
  const lib = require("bun:ffi").dlopen(process.platform === "darwin"
    ? "libSystem.dylib" : "libc.so.6", {
    close: {args: ["i32"], returns: "i32"},
  });
  if (lib.symbols.close(0) !== 0) throw new Error("stdin close failed");
  lib.close();
  return {$: CID(Unit)};
}
io_eff(CID(shut_stdin), shut_stdin);
