let count = 70;
io_eff(CID(now), () => ({ $: CID(Instant), value: ++count }));
