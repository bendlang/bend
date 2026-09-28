// IO
// ==

// IO.poll: io.poll is the running computation's frames, innermost first. A
// poll's frame answers Inl{x} once act ends in IO.poll.end, or Inr{hold}
// where act would park: io_holds (io.holds, set by the first poll), called
// by io_park_on and the channels under a frame, answers the poll at once
// (io.next) and the hold keeps the frames above the poll's. IO.resume puts
// them back over a raw frame, which answers its continuation the value
// alone, and runs the held effect again (a wait once it is ready, a
// channel's step at once); IO.cancel answers it with the cancel its park
// gave (a channel's), else halts.

function io_holds(w) {
  const io = globalThis.BEND_IO;
  let f = io.poll;
  let last = null;
  for (; f !== null && f.raw; f = f.up) {
    last = f;
  }
  if (f === null) {
    return false;
  }
  const again = w.again ?? (() => io_ready(w) ? w.more()
    : io_park_on(w.fd, w.out, w.k, w.more, w.at));
  const top = last === null ? null : io.poll;
  if (last !== null) {
    last.up = null;
  }
  io.poll = f.up;
  const hold = { k: w.k, again, cancel: w.cancel, top };
  io.next = f.k({ $: CID(Inr), value: hold });
  return true;
}

function io_ready(w) {
  if (w.at !== undefined && w.at <= performance.now()) {
    return true;
  }
  if (w.fd === undefined) {
    return w.at === undefined;
  }
  const sys = io_sys();
  const set = new Uint8Array((w.fd >> 6 << 3) + 8);
  set[w.fd >> 3] = 1 << (w.fd & 7);
  const p = sys.ptr(set);
  return sys.select(w.fd + 1, w.out ? null : p, w.out ? p : null, null,
    sys.ptr(new BigInt64Array(2))) > 0;
}

function io_poll_run(act, k) {
  const io = globalThis.BEND_IO;
  io.holds = io_holds;
  io.poll = { k, raw: false, up: io.poll };
  return { $: "$GO", op: act((x) => ({ $: CID(Emit), value: x })) };
}

function io_poll_end(x, k) {
  const io = globalThis.BEND_IO;
  const f = io.poll;
  io.poll = f.up;
  return { $: "$GO", op: f.k(f.raw ? x : { $: CID(Inl), value: x }) };
}

// Puts a held effect's frames back over a raw frame for k.
function io_poll_take(h, k) {
  const io = globalThis.BEND_IO;
  const g = { k, raw: true, up: io.poll };
  let f = h.top;
  while (f !== null && f.up !== null) {
    f = f.up;
  }
  if (f !== null) {
    f.up = g;
  }
  io.poll = h.top ?? g;
}

function io_resume(h, k) {
  io_poll_take(h, k);
  const x = h.again();
  return x === undefined ? undefined : { $: "$GO", op: h.k(x) };
}

function io_cancel(h, k) {
  io_poll_take(h, k);
  const halt = "IO.cancel: this effect cannot be cancelled yet";
  return { $: "$GO", op: h.cancel === undefined
    ? { $: CID(Halt), code: 1, message: halt } : h.k(h.cancel()) };
}

io_eff(CID(IO.poll.run), io_poll_run);
io_eff(CID(IO.poll.end), io_poll_end);
io_eff(CID(IO.resume), io_resume);
io_eff(CID(IO.cancel), io_cancel);
