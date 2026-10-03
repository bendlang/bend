function windowreftest_probe(display, id, title, close) {
  return { $: CID(False) };
}

io_eff(CID(WindowRefTest.probe), windowreftest_probe);
