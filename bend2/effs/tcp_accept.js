// TCP
// ===

// The loop parked the request until the listener was readable; an accept
// that still finds no connection (the listener is non-blocking) parks
// again. The accepted socket is non-blocking for life.
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

function tcp_accept_need() {
  return { read: true };
}
