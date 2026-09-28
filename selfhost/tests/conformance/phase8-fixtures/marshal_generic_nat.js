function good() {
  return {$: CID(Bundle), n: {$: CID(Some), value: 5n}, b: {$: CID(Some), value: true}};
}
function bad() {
  return {$: "Bogus", n: {$: CID(Some), value: 5n}, b: {$: CID(Some), value: true}};
}
io_eff(CID(good), good);
io_eff(CID(bad), bad);
