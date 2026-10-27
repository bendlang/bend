function window_fake(window) {
  throw new Error("Window.open returned a window on the JS backend");
}

io_eff(CID(fake), window_fake);
