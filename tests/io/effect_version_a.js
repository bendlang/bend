let count = 7;
io_eff(CID(now), () => ({ $: CID(Instant), value: ++count }));
