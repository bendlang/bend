// Window
// ==

// The browser playground answers from its own window table; everywhere
// else there is no display without a desktop session, hence 0x0.
function window_size(window) {
  if (typeof browser !== "undefined" && browser !== null
    && typeof browser.winSize === "function") {
    return browser.winSize(window);
  }
  return { $: "Tuple", fst: window,
    snd: { $: "Tuple", fst: 0, snd: 0 } };
}
