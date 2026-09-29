// IO
// ==

// IO.poll (see base.bend and io_poll.c, which this follows). io.poll is the
// running computation's frames, innermost first: a poll's (k, until), or a
// raw one (k). A polled act runs with io_poll_emit as its continuation, so
// the Emit that ends it pops the top frame. When the top frame is a
// poll's, io_poll_step takes a request whose effect gave io_eff a poll
// entry (fd "in" or "out" for its handle, time for a sleep, or wait,
// cancel and list for a channel step) and that would wait. A rest is the
// untouched request.

const io_poll_emit = (x) => ({ $: CID(Emit), value: x });

let io_poll_descs = null;

function io_poll_desc(op) {
  if (io_poll_descs === null) {
    io_poll_descs = new Map(Object.values($0eff).map((d) => [d.run, d.poll]));
  }
  return op.$ === "$FFI" ? io_poll_descs.get(op.run) : undefined;
}

function io_poll_ready(fd, out) {
  const sys = io_sys();
  const set = new Uint8Array((fd >> 6 << 3) + 8);
  set[fd >> 3] = 1 << (fd & 7);
  const p = sys.ptr(set);
  return sys.select(fd + 1, out ? null : p, out ? p : null, null,
    sys.ptr(new BigInt64Array(2))) > 0;
}

function io_poll_waits(d, args) {
  return d.wait !== undefined ? d.wait(...args)
    : d.time ? Number(args[0]) > 0 : !io_poll_ready(args[0], d.fd === "out");
}

// Answers the top frame, a poll's, Wait{rest} for op: the op to go on with.
function io_poll_hold(op) {
  const io = globalThis.BEND_IO;
  const p = io.poll;
  io.poll = p.up;
  return p.k({ $: CID(Wait), rest: op });
}

// Pops the top frame, answering x: the op to go on with.
function io_poll_pop(x) {
  const io = globalThis.BEND_IO;
  const f = io.poll;
  io.poll = f.up;
  return f.k(f.raw ? x : { $: CID(Ready), value: x });
}

// Answers io_run the op to go on with: op itself to run it as usual,
// another, or undefined to stop (it waits).
function io_poll_step(op) {
  const io = globalThis.BEND_IO;
  if (op.$ === CID(Emit)) {
    return io_poll_pop(op.value);
  }
  const p = io.poll;
  const d = p.raw ? undefined : io_poll_desc(op);
  if (d !== undefined && io_poll_waits(d, op.args)) {
    const now = performance.now();
    if (now >= p.until) {
      return io_poll_hold(op);
    }
    const late = () => {
      io_push((o) => o, io_poll_hold(op), false, io.poll);
      return undefined;
    };
    if (d.time) {
      if (now + Number(op.args[0]) <= p.until) {
        return op;
      }
      io_park_on(undefined, false, undefined, late, p.until);
    } else if (d.list !== undefined) {
      // parks on its row as usual; at until, if it still waits there, it
      // leaves the row and its poll holds it
      const ws = d.list(op.args[0]);
      op.run(...op.args, op.kont);
      io_park_on(undefined, false, undefined, () => {
        const i = ws.findIndex((w) => w.cont === op.kont);
        return i < 0 ? undefined : (ws.splice(i, 1), late());
      }, p.until);
    } else {
      const [fd, out] = [op.args[0], d.fd === "out"];
      io_park_on(fd, out, op.kont, () => io_poll_ready(fd, out)
        ? op.run(...op.args, op.kont) : late(), p.until);
    }
    return undefined;
  }
  // a polled act's last request (its continuation the act's end) that
  // needs no wait from the loop answers the top frame itself
  if (op.$ !== "$FFI" || op.kont !== io_poll_emit
    || (op.need !== undefined && d === undefined)) {
    return op;
  }
  const x = op.run(...op.args, op.kont);
  return x === undefined ? undefined : io_poll_pop(x);
}

function io_poll_run(ms, act, k) {
  const io = globalThis.BEND_IO;
  io.polled = io_poll_step;
  io.poll = { k, until: Number(ms) > 0 ? performance.now() + Number(ms) : 0,
    raw: false, up: io.poll };
  io_push(act, io_poll_emit, false, io.poll);
  return undefined;
}

// Puts a raw frame for k, unless it is a polled act's end.
function io_poll_back(k) {
  const io = globalThis.BEND_IO;
  if (k !== io_poll_emit) {
    io.poll = { k, until: 0, raw: true, up: io.poll };
  }
}

function io_resume(op, k) {
  io_poll_back(k);
  io_push((o) => o, op, false, globalThis.BEND_IO.poll);
  return undefined;
}

// Answers the request cancelled, not run: its entry's cancel, or (handle,
// Fail{ECANCELED}) for an effect on a handle.
function io_cancel(op, k) {
  io_poll_back(k);
  const d = io_poll_desc(op);
  const x = d.cancel !== undefined ? d.cancel(...op.args)
    : io_tup(op.args[0], io_fail(io_sys().mac ? 89 : 125));
  io_push(op.kont, x, false, globalThis.BEND_IO.poll);
  return undefined;
}

io_eff(CID(IO.poll), io_poll_run);
io_eff(CID(IO.resume), io_resume);
io_eff(CID(IO.cancel), io_cancel);
