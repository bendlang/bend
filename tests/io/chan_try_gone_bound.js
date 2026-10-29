// The channel's waiter queue length, live and gone (chan.js's q_size).
function peek_waiters(row) {
  return row.wait.xs.length - row.wait.head;
}

io_eff(CID(Peek.waiters), peek_waiters);
