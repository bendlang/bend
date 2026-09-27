// File
// ====

// File.sendfile(sock, file, off, len): the file's bytes from off, len of
// them, onto the socket, parking on a full one. Node has no sendfile(2),
// so this lane copies through one 64 KiB block at a time; pread leaves
// the file's position where it was. Done once all len are out; a file
// that ends first fails with ENODATA.
function file_sendfile(socket, file, off, len, k) {
  const sys = io_sys();
  const again = sys.mac ? 35 : 11;
  const b = new Uint8Array(65536);
  let pos = Number(off);
  const end = pos + Number(len);
  let have = 0;
  let at = 0;
  const done = (r) => io_tup(socket, io_tup(file, r));
  const go = () => {
    while (pos < end) {
      if (at === have) {
        const want = Math.min(b.length, end - pos);
        const n = Number(sys.pread(file, sys.ptr(b), want, BigInt(pos)));
        if (n < 0) {
          return done(io_fail(sys.errno()));
        }
        if (n === 0) {
          return done(io_fail(sys.mac ? 96 : 61));
        }
        have = n;
        at = 0;
      }
      const part = b.subarray(at, have);
      const w = Number(sys.send(socket, sys.ptr(part), part.length, 0));
      if (w < 0) {
        const code = sys.errno();
        if (code !== again) {
          return done(io_fail(code));
        }
        io_park_on(socket, true, k, () => go());
        return undefined;
      }
      at += w;
      pos += w;
    }
    return done(io_done({ $: CID(Unit) }));
  };
  return go();
}

io_eff(CID(File.sendfile), file_sendfile);
