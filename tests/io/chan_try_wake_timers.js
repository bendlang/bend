// bend-ids 1
// CID #Unit BEND_CID_Unit
// CID :Clock.stop BEND_CID_Clock_stop
// bend-ids end
// Stops the clock, so every later timer with the same bound is due at the
// same time and a woken waiter must find its own timer among equals.
function clock_stop() {
  const at = performance.now();
  performance.now = () => at;
  return { $: BEND_CID_Unit };
}

io_eff(BEND_CID_Clock_stop, clock_stop);
