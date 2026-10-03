const window_ref_test_owner = {};

function windowreftest_make() {
  return window_ref_test_owner;
}

function windowreftest_same(window) {
  return io_tup(window, { $: window === window_ref_test_owner ? CID(True) : CID(False) });
}

io_eff(CID(WindowRefTest.make), windowreftest_make);
io_eff(CID(WindowRefTest.same), windowreftest_same);
