let stdin_saved = -1;
let stdin_control;

function stdin_seed() {
  const ffi = require("bun:ffi");
  const sys = io_sys();
  stdin_control = ffi.dlopen(sys.mac ? "libSystem.dylib" : "libc.so.6", {
    pipe: { args: ["ptr"], returns: "i32" },
    dup2: { args: ["i32", "i32"], returns: "i32" }
  }).symbols;
  stdin_saved = sys.fcntl(0, sys.mac ? 67 : 1030, 3);
  const fds = new Int32Array(2);
  if (stdin_saved < 0 || stdin_control.pipe(ffi.ptr(fds)) < 0) {
    throw new Error("stdin fixture setup failed");
  }
  require("fs").writeSync(fds[1], Buffer.from("one\ntwo\n"));
  if (stdin_control.dup2(fds[0], 0) < 0) throw new Error("stdin fixture duplicate failed");
  sys.close(fds[0]); sys.close(fds[1]);
  return { $: CID(Unit) };
}

function stdin_close() {
  if (io_sys().close(0) !== 0) throw new Error("stdin fixture close failed");
  return { $: CID(Unit) };
}

function stdin_restore() {
  if (stdin_control.dup2(stdin_saved, 0) < 0) throw new Error("stdin fixture restore failed");
  io_sys().close(stdin_saved); stdin_saved = -1;
  return { $: CID(Unit) };
}

io_eff(CID(Input.seed), stdin_seed);
io_eff(CID(Input.close), stdin_close);
io_eff(CID(Input.restore), stdin_restore);
