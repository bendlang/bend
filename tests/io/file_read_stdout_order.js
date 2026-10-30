function raw_two() {
  require("fs").writeSync(1, "two\n");
  return { $: CID(Unit) };
}

io_eff(CID(raw_two), raw_two);
