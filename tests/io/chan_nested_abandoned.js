function host_abandon(c) {
  for (let i = 0; i < 200; i += 1) {
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
  }
  const entries = c.wait.xs.slice(c.wait.head);
  // The first entry is the live sender; every abandoned entry releases its item.
  if (entries.slice(1).some((w) => !w.gone || w.item !== undefined)) return 999;
  return entries.length;
}

io_eff(CID(Host.abandon), host_abandon);
