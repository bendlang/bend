// Window
// ======

// As in window.c: a NUL in the title, then a bad size, before the display.
function window_open(title, width, height) {
  if (title.includes("\0")) {
    return io_fail(process.platform === "darwin" ? 92 : 84);
  }
  if (width < 1 || height < 1 || width > 16384 || height > 16384) {
    return io_fail(22);
  }
  const code = process.platform === "darwin" ? 45 : 95;
  const text = "Window.open: no display (build a native binary with bend <file> -o <out> and run it from a desktop session)";
  return { $: CID(Fail), error: io_tup(code, text) };
}

io_eff(CID(Window.open), window_open);
