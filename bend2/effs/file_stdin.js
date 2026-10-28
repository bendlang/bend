// File
// ====

function file_stdin() {
  if (typeof Bun === "undefined") {
    return io_fail(process.platform === "darwin" ? 78 : 38);
  }
  try {
    const sys = io_sys();
    // F_DUPFD_CLOEXEC, with the runtime's existing variadic fcntl binding.
    const fd = sys.fcntl(0, sys.mac ? 67 : 1030, 3);
    return fd < 0 ? io_fail(sys.errno()) : io_done(fd);
  } catch (e) {
    return io_fail(Math.abs(e.errno ?? 5));
  }
}

io_eff(CID(File.stdin), file_stdin);
