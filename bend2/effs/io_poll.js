// IO
// ==

// IO.poll (see base.bend and io_poll.c, which this follows). io.poll is the
// running computation's frames, innermost first: a poll's (k, until), or a
// raw one (k). A polled act runs with io_poll_emit as its continuation, so
// the Emit that ends it pops the top frame. Under a poll's frame,
// io_poll_step takes a request whose effect gave io_eff a poll entry (fd
// "in" or "out" for its handle, time for a sleep, or wait, cancel and list
// for a channel step) and that would wait. A rest is { op, top }: the
// untouched request and the frames above the poll's.

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

// Answers p Inr{rest} for op, the frames above p going with it.
function io_poll_hold(p, op) {
  const io = globalThis.BEND_IO;
  const top = [];
  for (let f = io.poll; f !== p; f = f.up) {
    top.push(f);
  }
  io.poll = p.up;
  io_push(p.k, { $: CID(Inr), value: { op, top } }, false, io.poll);
}

function io_poll_step(op) {
  const io = globalThis.BEND_IO;
  if (op.$ === CID(Emit)) {
    const f = io.poll;
    io.poll = f.up;
    io_push(f.k, f.raw ? op.value : { $: CID(Inl), value: op.value }, false,
      io.poll);
    return true;
  }
  let p = io.poll;
  while (p !== null && p.raw) {
    p = p.up;
  }
  const d = p === null ? undefined : io_poll_desc(op);
  if (d === undefined || !io_poll_waits(d, op.args)) {
    return false;
  }
  const now = performance.now();
  const late = () => {
    io_poll_hold(p, op);
    return undefined;
  };
  if (now >= p.until) {
    io_poll_hold(p, op);
    return true;
  }
  if (d.time) {
    if (now + Number(op.args[0]) <= p.until) {
      return false;
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
  return true;
}

function io_poll_run(ms, act, k) {
  const io = globalThis.BEND_IO;
  io.polled = io_poll_step;
  io.poll = { k, until: Number(ms) > 0 ? performance.now() + Number(ms) : 0,
    raw: false, up: io.poll };
  io_push(act, io_poll_emit, false, io.poll);
  return undefined;
}

// Puts rest's frames back, over a raw frame for k unless it is a polled
// act's end.
function io_poll_back(rest, k) {
  const io = globalThis.BEND_IO;
  io.polled = io_poll_step;
  let up = k === io_poll_emit ? io.poll
    : { k, until: 0, raw: true, up: io.poll };
  for (let i = rest.top.length - 1; i >= 0; i -= 1) {
    rest.top[i].up = up;
    up = rest.top[i];
  }
  io.poll = up;
}

function io_resume(rest, k) {
  io_poll_back(rest, k);
  io_push((op) => op, rest.op, false, globalThis.BEND_IO.poll);
  return undefined;
}

// Answers the request cancelled, not run: its entry's cancel, or (handle,
// Fail{ECANCELED}) for an effect on a handle.
function io_cancel(rest, k) {
  io_poll_back(rest, k);
  const { op } = rest;
  const d = io_poll_desc(op);
  const x = d.cancel !== undefined ? d.cancel(...op.args)
    : io_tup(op.args[0], io_fail(io_sys().mac ? 89 : 125));
  io_push(op.kont, x, false, globalThis.BEND_IO.poll);
  return undefined;
}

io_eff(CID(IO.poll.run), io_poll_run);
io_eff(CID(IO.resume), io_resume);
io_eff(CID(IO.cancel), io_cancel);
