function pmake_at(d) {
  if (d === 0) {
    return { $: CID(Pe) };
  }
  return { $: CID(Pn), c: (d & 1) === 1, l: pmake_at(d - 1),
    k: (0xF0000000 + d) >>> 0, b: ((d >> 1) & 1) === 1, r: pmake_at(d - 1) };
}

io_eff(CID(pmake), pmake_at);
