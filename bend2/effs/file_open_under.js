// File
// ====

// path under root, read-only: each component is lstat'ed before the next
// and the end is opened with O_NOFOLLOW, so a symbolic link anywhere
// fails with ELOOP; an empty, "." or ".." component fails with EACCES;
// an end that is not a regular file with EISDIR or EACCES. A middle
// directory swapped for a link between two steps can still be followed:
// this lane is best-effort against a concurrent writer under root, and
// an intermediate needs only search permission.
function file_open_under(root, path) {
  const fs = require("fs");
  const mac = process.platform === "darwin";
  const top = io_bytes(root);
  const rel = io_bytes(path);
  if (top.includes(0) || rel.includes(0)) {
    return io_fail(mac ? 92 : 84);
  }
  const parts = [[]];
  for (const b of rel) {
    b === 47 ? parts.push([]) : parts[parts.length - 1].push(b);
  }
  let at = Buffer.from(top);
  try {
    if (!fs.statSync(at).isDirectory()) {
      return io_fail(20);
    }
    for (let i = 0; i < parts.length; i += 1) {
      const p = parts[i];
      if (p.length === 0 || (p[0] === 46 && (p.length === 1
        || (p.length === 2 && p[1] === 46)))) {
        return io_fail(13);
      }
      at = Buffer.concat([at, Buffer.from([47]), Buffer.from(p)]);
      const st = fs.lstatSync(at);
      if (st.isSymbolicLink()) {
        return io_fail(mac ? 62 : 40);
      }
      if (i < parts.length - 1 && !st.isDirectory()) {
        return io_fail(20);
      }
    }
    const c = fs.constants;
    const fd = fs.openSync(at, c.O_RDONLY | c.O_NOFOLLOW | c.O_NONBLOCK);
    const o = fs.fstatSync(fd);
    if (!o.isFile()) {
      fs.closeSync(fd);
      return io_fail(o.isDirectory() ? 21 : 13);
    }
    return io_done(fd);
  } catch (e) {
    return io_fail(-e.errno);
  }
}

io_eff(CID(File.open_under), file_open_under);
