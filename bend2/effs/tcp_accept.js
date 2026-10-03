// TCP
// ===

// An accept that finds no connection (the listener is non-blocking) parks
// until the listener is readable. The accepted socket is non-blocking for
// life.
function tcp_accept(listener, k) {
  const sys = io_sys();
  const lfd = listener;
  const go = () => {
    const fd = sys.accept(lfd, null, null);
    if (fd < 0) {
      const code = sys.errno();
      if (code === (sys.mac ? 35 : 11)) {
        io_park_on(lfd, false, k, go);
        return undefined;
      }
      return io_tup(listener, io_fail(code));
    }
    if (sys.fcntl(fd, 4, sys.fcntl(fd, 3, 0) | (sys.mac ? 4 : 0x800)) < 0) {
      const code = sys.errno();
      sys.close(fd);
      return io_tup(listener, io_fail(code));
    }
    return io_tup(listener, io_done(fd));
  };
  return go();
}

io_eff(CID(TCP.accept), tcp_accept);
