// IO
// ==

function io_write(text) {
  io_out(1, io_bytes(text));
  return { $: "Unit" };
}
