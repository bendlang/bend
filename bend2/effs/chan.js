// Chan
// ====

// Chan.new, send, recv and close share this file.

// A parked receiver holds CHAN_RECV: the C lane parks TERM_HOLE, and a
// program can make neither. A sent value may be null (an erased proof).
const CHAN_RECV = Symbol();

// A waiter IO.poll armed a deadline for (timer, io_poll.js) takes it out
// of the loop's waits when it wakes first.
function chan_wake(row, x) {
  const w = row.wait.shift();
  if (w.timer !== undefined) {
    const ws = globalThis.BEND_IO.waits;
    const i = ws.indexOf(w.timer);
    if (i >= 0) {
      ws.splice(i, 1);
    }
  }
  io_push(w.cont, x, false, w.poll);
  return w.item;
}

function chan_take(row) {
  const v = row.ring.shift();
  if (row.wait.length > 0) {
    row.ring.push(chan_wake(row, true));
  }
  return v;
}

// A handle is the row (a stale copy keeps it, shut).
function chan_shut(row) {
  row.shut = true;
  while (row.wait.length > 0) {
    chan_wake(row, row.wait[0].item === CHAN_RECV ? { $: CID(None) } : false);
  }
}

function chan_new(room) {
  return { room: Number(room), ring: [], wait: [], shut: false };
}

function chan_send(row, value, k) {
  if (row.shut) {
    return false;
  }
  if (row.wait.length > 0 && row.wait[0].item === CHAN_RECV) {
    chan_wake(row, { $: CID(Some), value: value });
    return true;
  }
  if (row.ring.length < row.room) {
    row.ring.push(value);
    return true;
  }
  row.wait.push({ cont: k, item: value, poll: globalThis.BEND_IO.poll });
  return;
}

function chan_recv(row, k) {
  if (row.ring.length > 0) {
    return { $: CID(Some), value: chan_take(row) };
  }
  if (row.wait.length > 0 && row.wait[0].item !== CHAN_RECV) {
    return { $: CID(Some), value: chan_wake(row, true) };
  }
  if (row.shut) {
    return { $: CID(None) };
  }
  row.wait.push({ cont: k, item: CHAN_RECV, poll: globalThis.BEND_IO.poll });
  return;
}

function chan_close(row) {
  if (!row.shut) {
    chan_shut(row);
  }
  return { $: CID(Unit) };
}

// IO.poll: when a step would wait, what a cancel answers, and the waits.
function chan_recvs(row) {
  return row.wait.length > 0 && row.wait[0].item === CHAN_RECV;
}

io_eff(CID(Chan.new), chan_new);

io_eff(CID(Chan.send), chan_send, undefined, {
  wait: (row) => !row.shut && !chan_recvs(row) && row.ring.length >= row.room,
  cancel: () => false,
  list: (row) => row.wait });
io_eff(CID(Chan.recv), chan_recv, undefined, {
  wait: (row) => !row.shut && row.ring.length === 0
    && (row.wait.length === 0 || chan_recvs(row)),
  cancel: () => ({ $: CID(None) }),
  list: (row) => row.wait });
io_eff(CID(Chan.close), chan_close);
