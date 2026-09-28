// Window
// ======

function window_frame(window, image) {
  return { $: CID(Tuple), fst: window,
    snd: { $: CID(Tuple), fst: image, snd: { $: CID(Nil) } } };
}

io_eff(CID(Window.frame), window_frame);
