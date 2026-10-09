// IO
// ==

function io_now() {
  return BigInt(Math.floor(performance.now()));
}

io_eff(CID(IO.now), io_now);

function io_clock(which) {
  const ms = performance.now()
    + (which.$ === CID(Wall) ? performance.timeOrigin : 0);
  const seconds = Math.floor(ms / 1000);
  if (seconds < 0 || seconds > 281474976710655) {
    throw new Error("bend: a clock second count outside Nat's range");
  }
  return { $: CID(Tuple), fst: BigInt(seconds),
    snd: Math.floor((ms - seconds * 1000) * 1000000) };
}

io_eff(CID(IO.clock), io_clock);
