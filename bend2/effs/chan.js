// Chan
// ====

// Chan.new, send, recv and close share this file.

// A parked receiver holds CHAN_RECV: the C lane parks TERM_HOLE, and a
// program can make neither. A sent value may be null (an erased proof).
const CHAN_RECV = Symbol();

function chan_wake(row, x) {
  const w = row.wait.shift();
  io_push(w.cont, x, false);
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
    chan_wake(row, row.wait[0].item === CHAN_RECV ? { $: "None" } : false);
  }
}

function chan_new(room) {
  return { room: Number(room), ring: [], wait: [], shut: false };
}

function chan_send(handle, value, k) {
  const row = handle;
  if (row.shut) {
    return false;
  }
  if (row.wait.length > 0 && row.wait[0].item === CHAN_RECV) {
    chan_wake(row, { $: "Some", value: value });
    return true;
  }
  if (row.ring.length < row.room) {
    row.ring.push(value);
    return true;
  }
  row.wait.push({ cont: k, item: value });
  return;
}

function chan_recv(handle, k) {
  const row = handle;
  if (row.ring.length > 0) {
    return { $: "Some", value: chan_take(row) };
  }
  if (row.wait.length > 0 && row.wait[0].item !== CHAN_RECV) {
    return { $: "Some", value: chan_wake(row, true) };
  }
  if (row.shut) {
    return { $: "None" };
  }
  row.wait.push({ cont: k, item: CHAN_RECV });
  return;
}

function chan_close(handle) {
  const row = handle;
  if (!row.shut) {
    chan_shut(row);
  }
  return { $: "Unit" };
}
