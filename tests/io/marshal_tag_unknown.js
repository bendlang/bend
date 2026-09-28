function good() {
  return {$: CID(Box), n: 5n};
}
function bad() {
  return {$: "Bogus", n: 5n};
}

io_eff(CID(good), good);
io_eff(CID(bad), bad);
