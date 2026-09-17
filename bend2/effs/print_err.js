// IO
// ==

function io_print_err(text) {
  io_out(2, io_bytes(text + "\n"));
  return { $: "Unit" };
}
