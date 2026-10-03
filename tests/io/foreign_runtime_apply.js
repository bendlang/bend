function native_apply(step, value) {
  console.log(step(value));
  return { $: CID(Unit) };
}

io_eff(CID(native.apply), native_apply);
