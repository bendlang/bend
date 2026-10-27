// bend-ids 1
// CID :title BEND_CID_title
// bend-ids end
function window_title(window) {
  throw new Error("Window.open returned a window on the JS backend");
}

io_eff(BEND_CID_title, window_title);
