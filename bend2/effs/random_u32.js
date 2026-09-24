// IO
// ==

function io_random_u32() {
  return io_done(crypto.getRandomValues(new Uint32Array(1))[0]);
}

io_eff(CID(IO.random_u32), io_random_u32);
