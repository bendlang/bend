// Tree
// ====

// A balanced tree of the depth asked, its leaves 1.. left to right, every
// odd one Empty, as the C lays it.
function tree_make(depth) {
  let next = 0;
  const at = (d) => {
    if (d === 0) {
      next += 1;
      return next % 2 === 1 ? { $: "Empty" } : { $: "Leaf", v: next };
    }
    const l = at(d - 1);
    return { $: "Node", l, r: at(d - 1) };
  };
  return at(depth);
}

// Chain
// =====

function chain_make(n) {
  let c = { $: "End" };
  for (let i = 0; i < n; i += 1) {
    c = { $: "Cell", v: i, next: c };
  }
  return c;
}
