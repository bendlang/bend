// Socket
// ======

function socket_close(socket) {
  const sys = io_sys();
  sys.close(socket);
  return { $: "Unit" };
}
