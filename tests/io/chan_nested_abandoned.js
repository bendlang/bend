// A nested IO spawns 300 senders and receives them all: sheds while they
// park raise keep, which their wakes must lower again.
function host_drain(c) {
  const n = 300;
  const recv = (i, k) => i === n ? k({ $: CID(Unit) })
    : { $: CID(Chan.recv), args: [c], kont: () => recv(i + 1, k) };
  const spawn = (i, k) => i === n ? recv(0, k) : {
    $: CID(IO.spawn), args: [(j) => ({ $: CID(Chan.send), args: [c, i], kont: j })],
    kont: () => spawn(i + 1, k),
  };
  if (io_run(() => (k) => spawn(0, k)) !== 0) {
    throw new Error("nested IO ended unexpectedly");
  }
  return { $: CID(Unit) };
}

// Then nested IOs park senders behind a live one and exit or throw: the
// longest the queue gets is the answer.
function host_abandon(c) {
  let most = 0;
  for (let i = 0; i < 600; i += 1) {
    let code;
    let caught = false;
    try {
      code = io_run(() => (k) => ({
        $: CID(IO.spawn), args: [() => i % 4 < 2
          ? { $: "Exit", code: 0 } : { $: "missing nested effect", args: [] }],
        kont: () => i % 2 === 0
          ? { $: CID(Chan.send), args: [c, i], kont: k }
          : { $: CID(Chan.try_send), args: [c, i, 60000], kont: k },
      }));
    } catch (e) {
      if (e !== "bend: no effect registers missing nested effect") throw e;
      caught = true;
      code = 0;
    }
    if (code !== 0 || caught !== (i % 4 >= 2)) {
      throw new Error("nested IO ended unexpectedly");
    }
    most = Math.max(most, c.wait.xs.length - c.wait.head);
  }
  return most;
}

io_eff(CID(Host.drain), host_drain);
io_eff(CID(Host.abandon), host_abandon);
