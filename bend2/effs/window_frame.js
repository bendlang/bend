// Window
// ======

function window_frame(window, image) {
  return { $: "Tuple", fst: window,
    snd: { $: "Tuple", fst: image, snd: { $: "Nil" } } };
}
