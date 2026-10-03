function window_export_ref(window) {
  const code = process.platform === "darwin" ? 45 : 95;
  const text = "Window.export_ref: external reference is unavailable on this backend";
  return io_tup(window, { $: CID(Fail), error: io_tup(code, text) });
}

io_eff(CID(Window.export_ref), window_export_ref);
