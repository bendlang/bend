// Window
// ======

function window_open_error(name) {
  const code = process.platform === "darwin" ? 45 : 95;
  const text = name + ": no display (build a native binary with bend <file> -o <out> and run it from a desktop session)";
  return { $: CID(Fail), error: { $: CID(Tuple), fst: code, snd: text } };
}

function window_open(title, width, height) {
  return window_open_error("Window.open");
}

function window_open_resizable(title, width, height) {
  return window_open_error("Window.open_resizable");
}

io_eff(CID(Window.open), window_open);
io_eff(CID(Window.open_resizable), window_open_resizable);
