// Listener
// ========

function listener_close(listener) {
  const sys = io_sys();
  sys.close(listener);
  return { $: CID(Unit) };
}

io_eff(CID(Listener.close), listener_close);
