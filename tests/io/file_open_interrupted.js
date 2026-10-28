// The JS lane uses the host's ordinary file opens.
function interrupted_unit() {
  return { $: CID(Unit) };
}

io_eff(CID(Interrupted.arm), interrupted_unit);
io_eff(CID(Interrupted.check), interrupted_unit);
