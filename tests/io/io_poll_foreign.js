// The JS twin of io_poll_foreign.c: the poll entry { fd: "in" }.

function recv1(socket, k) {
  const sys = io_sys();
  const b = new Uint8Array(1);
  const go = () => {
    const n = Number(sys.recv(socket, sys.ptr(b), 1, 0));
    if (n < 0) {
      const code = sys.errno();
      if (code === (sys.mac ? 35 : 11)) {
        io_park_on(socket, false, k, go);
        return undefined;
      }
      return io_tup(socket, io_fail(code));
    }
    return io_tup(socket, io_done(n === 1 ? b[0] : 256));
  };
  return go();
}

io_eff(CID(recv1), recv1, undefined, { fd: "in" });
