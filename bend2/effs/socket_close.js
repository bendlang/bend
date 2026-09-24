// Socket
// ======

function socket_close(socket) {
  const sys = io_sys();
  sys.close(socket);
  return { $: CID(Unit) };
}

io_eff(CID(Socket.close), socket_close);
