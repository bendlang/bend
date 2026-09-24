function zero() {
  return 0n;
}
function five() {
  return 5n;
}
function neg() {
  return -3n;
}

io_eff(CID(zero), zero);
io_eff(CID(five), five);
io_eff(CID(neg), neg);
