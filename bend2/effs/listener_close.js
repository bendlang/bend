// Listener
// ========

function listener_close(listener) {
  const sys = io_sys();
  sys.close(listener);
  return { $: "Unit" };
}
