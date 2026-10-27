// Stops the clock, so every later timer with the same bound is due at the
// same time and a woken waiter must find its own timer among equals; starts
// it again, so the process's later timers still come due.
const clock_now = performance.now;

function clock_stop() {
  const at = performance.now();
  performance.now = () => at;
  return { $: CID(Unit) };
}

function clock_start() {
  performance.now = clock_now;
  return { $: CID(Unit) };
}

io_eff(CID(Clock.stop), clock_stop);
io_eff(CID(Clock.start), clock_start);
