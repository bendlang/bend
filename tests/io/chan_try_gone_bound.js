// bend-ids 1
// CID :Peek.waiters BEND_CID_Peek_waiters
// bend-ids end
// The channel's waiter queue length, live and gone (chan.js's q_size).
function peek_waiters(row) {
  return row.wait.xs.length - row.wait.head;
}

io_eff(BEND_CID_Peek_waiters, peek_waiters);
