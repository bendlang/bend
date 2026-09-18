// An unlinked sparse fixture, seeded independently of File.write_bytes.
function sparse_open() {
  const fs = require("fs");
  const path = require("path");
  const dir = fs.mkdtempSync(path.join(require("os").tmpdir(), "bend-sparse-"));
  const name = path.join(dir, "file");
  let fd;
  try {
    fd = fs.openSync(name, "w+");
    fs.unlinkSync(name);
    const bytes = Buffer.from([128, 0, 255]);
    if (fs.writeSync(fd, bytes, 0, 3, 4294967303) !== 3) {
      fs.closeSync(fd);
      return io_fail(5);
    }
    return io_done(fd);
  } catch (e) {
    if (fd !== undefined) fs.closeSync(fd);
    return io_fail(-e.errno);
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}
