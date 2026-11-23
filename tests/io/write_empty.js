// Queues stdout as a pipe would (comp.ts's io_std), even when it is a TTY.
function stdout_hold() {
  if (!io_held) {
    io_held = [];
  }
  return { $: CID(Unit) };
}

// The chunks stdout's queue holds until its next flush.
function stdout_held() {
  return io_held.length;
}

io_eff(CID(Stdout.hold), stdout_hold);
io_eff(CID(Stdout.held), stdout_held);
