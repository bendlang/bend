function list_new(k) {
  let out = {$: "Nil"};
  for (let i = 0; i < k; i++) {
    out = {$: "Con", $0: (i & 0xff) >>> 0, $1: out};
  }
  return out;
}
function list_sum(xs) {
  let n = 0;
  while (xs.$ === "Con") {
    n = (n + xs.$0) >>> 0;
    xs = xs.$1;
  }
  return n;
}
