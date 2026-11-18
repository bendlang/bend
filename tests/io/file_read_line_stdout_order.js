// The JS lane reads through the host, with no read to interpose.
function read_arm(file) {
  return file;
}

function wait_for_read() {
  return { $: CID(Unit) };
}

io_eff(CID(read_arm), read_arm);
io_eff(CID(wait_for_read), wait_for_read);
