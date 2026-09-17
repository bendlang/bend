function fold2(f) {
  return f(f(1)(2))(3);
}
function pick_fn(m) {
  if (m.$ === "Some") {
    return m.value(40);
  }
  return 0;
}
function stepper() {
  return {$: "Some", value: (x) => (x + 100) >>> 0};
}
