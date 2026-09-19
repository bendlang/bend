// Window
// ======

// The page shows the posted pixels; the drained input queue answers as
// the frame's event list, arrival order, like the native pump.
function window_frame(window, image, k) {
  if (typeof browser !== "undefined" && browser !== null
    && typeof browser.winFrame === "function") {
    const out = browser.winFrame(window, image);
    io_pace(k, () => out);
    return undefined;
  }
  return { $: "Tuple", fst: window,
    snd: { $: "Tuple", fst: image, snd: { $: "Nil" } } };
}
