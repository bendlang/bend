// Window
// ======

function window_set_title(window, title) {
  if (typeof browser !== "undefined" && browser !== null
    && typeof browser.winTitle === "function") {
    return browser.winTitle(window, title);
  }
  return window;
}
