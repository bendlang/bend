// Socket and Listener
// ===================

function socket_close(socket) {
  const sys = io_sys();
  sys.close(socket);
  return { $: "Unit" };
}

const listener_close = socket_close;
