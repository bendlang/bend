function file_64_new() {
  const fs = require("fs");
  const path = require("path");
  const name = path.join(require("os").tmpdir(), "bend-file64-" + require("crypto").randomUUID());
  const fd = fs.openSync(name, "wx+", 0o600);
  try {
    fs.unlinkSync(name);
    return fd;
  } catch (error) {
    fs.closeSync(fd);
    fs.rmSync(name, { force: true });
    throw error;
  }
}
io_eff(CID(Host.file), file_64_new);
