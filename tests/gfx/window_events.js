function window_feed(window) {
  throw new Error("Window.open returned a window on the JS backend");
}

io_eff(CID(feed), window_feed);
