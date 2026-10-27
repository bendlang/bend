// Stops the clock, so every later timer with the same bound is due at the
// same time and a woken waiter must find its own timer among equals.
function clock_stop() {
  const at = performance.now();
  performance.now = () => at;
  return { $: CID(Unit) };
}

io_eff(CID(Clock.stop), clock_stop);
