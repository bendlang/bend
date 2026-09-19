// IO
// ==

function io_random_u32() {
  return io_done(crypto.getRandomValues(new Uint32Array(1))[0]);
}
