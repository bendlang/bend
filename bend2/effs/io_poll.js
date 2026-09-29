// IO
// ==

// IO.poll (see base.bend and io_poll.c, which this follows). io.poll is the
// running computation's poll frames, innermost first: (k, until, late,
// own), until clipped to the enclosing frame's. A polled act runs with
// io_poll_emit as its continuation, so the Emit that ends it pops the top
// frame. Under a frame, io_poll_step takes a request whose effect gave
// io_eff a poll entry (fd "in" or "out" for its handle, time for a sleep,
// or wait, cancel and list for a channel step) and that would wait, and
// answers it cancelled at the frame's until, yielding as a wait would. A
// channel step's waiter owns its deadline (timer): chan_wake takes it out
// of the loop's waits.

const io_poll_emit = (x) => ({ $: CID(Emit), value: x });

let io_poll_descs = null;

function io_poll_desc(op) {
  if (io_poll_descs === null) {
    io_poll_descs = new Map(Object.values($0eff).map((d) => [d.run, d.poll]));
  }
  return op.$ === "$FFI" ? io_poll_descs.get(op.run) : undefined;
}

let io_poll_set = new Uint8Array(128);
const io_poll_tv = new BigInt64Array(2);

function io_poll_ready(fd, out) {
  const sys = io_sys();
  const len = (fd >> 6 << 3) + 8;
  if (io_poll_set.length < len) {
    io_poll_set = new Uint8Array(len);
  }
  io_poll_set.fill(0, 0, len);
  io_poll_set[fd >> 3] = 1 << (fd & 7);
  io_poll_tv.fill(0n);
  const p = sys.ptr(io_poll_set);
  return sys.select(fd + 1, out ? null : p, out ? p : null, null,
    sys.ptr(io_poll_tv)) > 0;
}

function io_poll_waits(d, args) {
  return d.wait !== undefined ? d.wait(...args)
    : d.time ? Number(args[0]) > 0 : !io_poll_ready(args[0], d.fd === "out");
}

// Pops the top frame, answering x: the op to go on with.
function io_poll_pop(x) {
  const io = globalThis.BEND_IO;
  const f = io.poll;
  io.poll = f.up;
  return f.k({ $: f.late ? CID(Late) : CID(Ready), value: x });
}

// op cancelled, unrun, under frame p: p and the frames up to the one whose
// deadline it was turn late; the op to go on with (its entry's cancel, or
// (handle, Fail{ECANCELED}) on a handle).
function io_poll_cancel(p, d, op) {
  for (let f = p; ; f = f.up) {
    f.late = true;
    if (f === f.own) {
      break;
    }
  }
  const x = d.cancel !== undefined ? d.cancel(...op.args)
    : io_tup(op.args[0], io_fail(io_sys().mac ? 89 : 125));
  return op.kont === io_poll_emit ? io_poll_pop(x) : op.kont(x);
}

// Answers io_run the op to go on with: op itself to run it as usual,
// another, or undefined to stop (it waits, or was requeued).
function io_poll_step(op) {
  const io = globalThis.BEND_IO;
  if (op.$ === CID(Emit)) {
    return io_poll_pop(op.value);
  }
  const p = io.poll;
  const d = io_poll_desc(op);
  if (d !== undefined && io_poll_waits(d, op.args)) {
    const now = p.until === 0 ? 0 : performance.now();
    const late = () => {
      io_push((o) => o, io_poll_cancel(p, d, op), false, io.poll);
      return undefined;
    };
    if (now >= p.until) {
      return late();
    }
    if (d.time) {
      if (now + Number(op.args[0]) <= p.until) {
        return op;
      }
      io_park_on(undefined, false, undefined, late, p.until);
    } else if (d.list !== undefined) {
      // parks on its row as usual, then arms its deadline: at until, if it
      // still waits there (the same entry), it leaves the row
      const ws = d.list(op.args[0]);
      op.run(...op.args, op.kont);
      const entry = ws[ws.length - 1];
      const more = () => {
        const i = ws.indexOf(entry);
        return i < 0 ? undefined : (ws.splice(i, 1), late());
      };
      io_park_on(undefined, false, undefined, more, p.until);
      entry.timer = io.waits.find((w) => w.more === more);
    } else {
      const [fd, out] = [op.args[0], d.fd === "out"];
      io_park_on(fd, out, op.kont, () => io_poll_ready(fd, out)
        ? op.run(...op.args, op.kont) : late(), p.until);
    }
    return undefined;
  }
  // a polled act's last request (its continuation the act's end) that
  // needs no wait from the loop answers the frame itself
  if (op.$ !== "$FFI" || op.kont !== io_poll_emit
    || (op.need !== undefined && d === undefined)) {
    return op;
  }
  const x = op.run(...op.args, op.kont);
  return x === undefined ? undefined : io_poll_pop(x);
}

function io_poll_run(ms, act, k) {
  const io = globalThis.BEND_IO;
  const up = io.poll;
  const until = Number(ms) > 0 ? performance.now() + Number(ms) : 0;
  const clip = up !== null && up.until <= until;
  const p = { k, until: clip ? up.until : until, late: false, own: null, up };
  p.own = clip ? up.own : p;
  io.polled = io_poll_step;
  io.poll = p;
  io_push(act, io_poll_emit, false, p);
  return undefined;
}

io_eff(CID(IO.poll), io_poll_run);
