// Window
// ======

function window_close(window) {
  if (typeof browser !== "undefined" && browser !== null
    && typeof browser.winClose === "function") {
    return browser.winClose(window);
  }
  return { $: "Unit" };
}
