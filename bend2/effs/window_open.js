// Window
// ======

// In the browser playground a canvas stands in for the display: the page
// is told to open it, and frames are rasterized worker-side and posted
// over. Everywhere else this still fails without a display.
function window_open(title, width, height) {
  if (typeof browser !== "undefined" && browser !== null
    && typeof browser.winOpen === "function") {
    return browser.winOpen(title, width, height);
  }
  const code = process.platform === "darwin" ? 45 : 95;
  const text = "Window.open: no display (build a native binary with bend <file> -o <out> and run it from a desktop session)";
  return { $: "Fail", error: { $: "Tuple", fst: code, snd: text } };
}
