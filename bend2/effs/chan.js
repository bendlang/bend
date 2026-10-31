// Chan
// ====

// Chan.new, send, recv, close and the try_ twins share this file.

// A parked receiver holds CHAN_RECV: the C lane parks TERM_HOLE, and a
// program can make neither. A sent value may be null (an erased proof).
const CHAN_RECV = Symbol();

function chan_done() {
  return { $: CID(Done), value: { $: CID(Unit) } };
}

function chan_wait(item) {
  return { $: CID(Wait), rest: item === CHAN_RECV ? { $: CID(Unit) } : item };
}

// The buffer and the waiters are queues, xs[head..]: Array.shift drains n in
// n^2 on V8, so a pull moves head, and compacts once head passes the live
// ones + 64, so a pull moves O(1) of them.
function q_new() {
  return { xs: [], head: 0 };
}

function q_size(q) {
  return q.xs.length - q.head;
}

function q_push(q, x) {
  q.xs.push(x);
}

function q_pull(q) {
  const x = q.xs[q.head];
  q.xs[q.head] = undefined;
  q.head += 1;
  const live = q_size(q);
  if (live === 0 || q.head > live + 64) {
    q.xs.copyWithin(0, q.head);
    q.xs.length = live;
    q.head = 0;
  }
  return x;
}

// A waiter that will never wake: gone, or its IO has returned.
function chan_dead(w) {
  return w.gone || w.io.done;
}

// The first waiter, past those whose IO has returned (a nested io_run): their
// computations are gone with it, so the row drops them and their items; and
// past those whose try_ timer came first, which left without a wake.
function chan_head(row) {
  let w = row.wait.xs[row.wait.head];
  while (w !== undefined && chan_dead(w)) {
    row.dead -= w.gone ? 1 : 0;
    q_pull(row.wait);
    w = row.wait.xs[row.wait.head];
  }
  return w;
}

// Where timer t is in ws, which io_park_on keeps sorted by at: a binary search
// to the first timer due at t.at, then past others due at the same time. -1 if
// the poller has taken it.
function chan_timer(ws, t) {
  let i = 0;
  for (let hi = ws.length; i < hi;) {
    const mid = (i + hi) >> 1;
    if (ws[mid].at < t.at) i = mid + 1;
    else hi = mid;
  }
  while (i < ws.length && ws[i] !== t && ws[i].at === t.at) i += 1;
  return ws[i] === t ? i : -1;
}

// Wakes the first live waiter with x, as Ready{x} if try_ (cutting its timer,
// if the poller has not taken it yet), on the IO that parked it: a nested
// io_run may wake an outer one.
function chan_wake(row, x) {
  const w = chan_head(row);
  q_pull(row.wait);
  w.gone = true;
  row.keep -= row.keep > 0 ? 1 : 0;
  if (w.late !== undefined) {
    const ws = w.io.waits;
    const i = chan_timer(ws, w.timer);
    if (i >= 0) ws.splice(i, 1);
    x = { $: CID(Ready), value: x };
  }
  io_push(w.cont, x, false, w.io);
  return w.item;
}

function chan_take(row) {
  const v = q_pull(row.ring);
  if (chan_head(row) !== undefined) {
    q_push(row.ring, chan_wake(row, chan_done()));
  }
  return v;
}

// A handle is the row (a stale copy keeps it, shut).
function chan_shut(row) {
  row.shut = true;
  for (let w; (w = chan_head(row)) !== undefined;) {
    chan_wake(row, w.item === CHAN_RECV ? { $: CID(None) }
      : { $: CID(Fail), error: w.item });
  }
}

// Drops the waiters that will never wake, with their items, in one pass.
// keep is how many were left; each wake lowers it, so it may fall under the
// live ones, but never rises until the next shed.
function chan_shed(row) {
  const q = row.wait;
  let n = 0;
  for (let i = q.head; i < q.xs.length; i += 1) {
    if (!chan_dead(q.xs[i])) q.xs[n++] = q.xs[i];
  }
  q.xs.length = n;
  q.head = 0;
  row.dead = 0;
  row.keep = n;
}

// A late w stays in the queue, gone and holding nothing, for chan_head to
// drop when it comes first. Once the gone outnumber the rest by 64, the
// queue sheds them all, so a timeout costs O(1) and the gone stay under
// the rest+64, even behind a waiter that is never woken. The rest counts
// waiters whose IO returned, which chan_park bounds.
function chan_late(row, w) {
  w.gone = true;
  w.io = w.cont = w.item = w.late = w.timer = undefined;
  row.dead += 1;
  if (row.dead > q_size(row.wait) - row.dead + 64) chan_shed(row);
}

// Parks k on row with item; with ms, a timer too, whose late answers Wait:
// the first of the two to come cuts the other. A waiter whose IO returns is
// not counted dead, so a park sheds once the queue passes twice keep + 64,
// at O(1) a park. Behind a live waiter, those stay under twice the waiters
// live at the last shed + 64 (not the live now: a waiter kept there may have
// lost its IO since), and go only at a later park on row.
function chan_park(row, k, item, ms) {
  if (q_size(row.wait) > row.keep * 2 + 64) chan_shed(row);
  const w = { io: io_active, cont: k, item: item, gone: false };
  if (ms !== undefined) {
    w.late = () => {
      // An earlier callback of the same ready batch may have woken w.
      if (w.gone) return undefined;
      chan_late(row, w);
      return chan_wait(item);
    };
    w.timer = io_park_on(undefined, false, k, w.late, io_until(ms));
  }
  q_push(row.wait, w);
  return undefined;
}

// Sends without waiting: Done{}, Fail{v} if closed, undefined if it would.
function chan_put(row, value) {
  if (row.shut) {
    return { $: CID(Fail), error: value };
  }
  if (chan_head(row)?.item === CHAN_RECV) {
    chan_wake(row, { $: CID(Some), value: value });
    return chan_done();
  }
  if (q_size(row.ring) < row.room) {
    q_push(row.ring, value);
    return chan_done();
  }
  return undefined;
}

// Receives without waiting: Some{v}, None{} at the end, undefined if not.
function chan_get(row) {
  if (q_size(row.ring) > 0) {
    return { $: CID(Some), value: chan_take(row) };
  }
  const w = chan_head(row);
  if (w !== undefined && w.item !== CHAN_RECV) {
    return { $: CID(Some), value: chan_wake(row, chan_done()) };
  }
  if (row.shut) {
    return { $: CID(None) };
  }
  return undefined;
}

// Ready{x} now, Wait{rest} now if ms is 0, else parks until a wake or ms.
function chan_try(row, x, item, ms, k) {
  if (x !== undefined) {
    return { $: CID(Ready), value: x };
  }
  if (Number(ms) === 0) {
    return chan_wait(item);
  }
  return chan_park(row, k, item, Number(ms));
}

function chan_new(room) {
  return { room: Number(room), ring: q_new(), wait: q_new(), dead: 0,
    keep: 0, shut: false };
}

function chan_send(row, value, k) {
  const x = chan_put(row, value);
  return x !== undefined ? x : chan_park(row, k, value);
}

function chan_recv(row, k) {
  const x = chan_get(row);
  return x !== undefined ? x : chan_park(row, k, CHAN_RECV);
}

function chan_try_send(row, value, ms, k) {
  return chan_try(row, chan_put(row, value), value, ms, k);
}

function chan_try_recv(row, ms, k) {
  return chan_try(row, chan_get(row), CHAN_RECV, ms, k);
}

function chan_close(row) {
  if (!row.shut) {
    chan_shut(row);
  }
  return { $: CID(Unit) };
}

io_eff(CID(Chan.new), chan_new);
io_eff(CID(Chan.send), chan_send);
io_eff(CID(Chan.recv), chan_recv);
io_eff(CID(Chan.try_send), chan_try_send);
io_eff(CID(Chan.try_recv), chan_try_recv);
io_eff(CID(Chan.close), chan_close);
