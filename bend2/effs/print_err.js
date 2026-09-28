// IO
// ==

function io_print_err(text) {
  io_out(2, io_bytes(text + "\n"));
  return { $: CID(Unit) };
}

io_eff(CID(IO.print_err), io_print_err);
