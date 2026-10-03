function native_emit(value) {
  console.log(value);
  return { $: CID(Unit) };
}

io_eff(CID(native.emit), native_emit);
