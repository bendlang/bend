// IO
// ==

function io_sleep(ms) {
  return { $: CID(Unit) };
}

function io_sleep_need() {
  return { time: true };
}

io_eff(CID(IO.sleep), io_sleep, io_sleep_need);
