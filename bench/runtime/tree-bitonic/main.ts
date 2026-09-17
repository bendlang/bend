// TypeScript twin of main.bend: same tree-shaped bitonic sorting
// network, key generator and Stat verification scan, single-threaded.
// Tree nodes are class instances (monomorphic shapes); the GC plays the
// role of the linear frees.
class Leaf {
    v: number;
  constructor(v: number) {
    this.v = v;
  }
}
class Fork {
    l: Tree;
  r: Tree;
  constructor(l: Tree, r: Tree) {
    this.l = l;
    this.r = r;
  }
}
type Tree = Leaf | Fork;

type Stat = { lo: number; hi: number; ok: number; mx: number };

const SIZE = 23;

function word_prng(x: number): number {
  const b = (x ^ (x << 13)) >>> 0;
  const d = (b ^ (b >>> 17)) >>> 0;
  return (d ^ (d << 5)) >>> 0;
}
function word_key(i: number): number {
  return word_prng(Math.imul(i + 1, 2654435761) >>> 0);
}

function tree_swap(s: number, a: number, b: number): Tree {
  return s === 0
    ? new Fork(new Leaf(a), new Leaf(b))
    : new Fork(new Leaf(b), new Leaf(a));
}
function tree_warp_zip(wa: Tree, wb: Tree): Tree {
  if (wa instanceof Fork && wb instanceof Fork) {
    return new Fork(new Fork(wa.l, wb.l), new Fork(wa.r, wb.r));
  }
  return new Leaf(0);
}
function tree_warp(s: number, a: Tree, b: Tree): Tree {
  if (a instanceof Leaf && b instanceof Leaf) {
    return tree_swap(s ^ (a.v > b.v ? 1 : 0), a.v, b.v);
  }
  if (a instanceof Fork && b instanceof Fork) {
    return tree_warp_zip(tree_warp(s, a.l, b.l), tree_warp(s, a.r, b.r));
  }
  return new Leaf(0);
}
// mode 0 warps the halves, mode 1 descends one level shallower
function tree_flow(d: number, m: number, s: number, t: Tree): Tree {
  if (d === 0) return t;
  if (m === 0) {
    if (!(t instanceof Fork)) return t;
    return tree_flow(d - 1, 1, s, tree_warp(s, t.l, t.r));
  }
  if (!(t instanceof Fork)) return t;
  return new Fork(tree_flow(d, 0, s, t.l), tree_flow(d, 0, s, t.r));
}
function tree_sort_1(d: number, s: number, sa: Tree, sb: Tree): Tree {
  return tree_flow(d, 0, s, new Fork(sa, sb));
}
function tree_bsort(d: number, s: number, x: number): Tree {
  if (d === 0) return new Leaf(word_key(x));
  const sa = tree_bsort(d - 1, 0, (x * 2 + 1) >>> 0);
  const sb = tree_bsort(d - 1, 1, (x * 2) >>> 0);
  return tree_sort_1(d, s, sa, sb);
}

function stat_join(a: Stat, b: Stat): Stat {
  return {
    lo: a.lo,
    hi: b.hi,
    ok: a.ok & b.ok & (a.hi <= b.lo ? 1 : 0),
    mx: (Math.imul(a.mx, 2654435761) + b.mx) >>> 0,
  };
}
function tree_scan(d: number, t: Tree): Stat {
  if (d === 0) {
    const v = t instanceof Leaf ? t.v : 0;
    return { lo: v, hi: v, ok: 1, mx: v };
  }
  if (!(t instanceof Fork)) return { lo: 0, hi: 0, ok: 0, mx: 0 };
  return stat_join(tree_scan(d - 1, t.l), tree_scan(d - 1, t.r));
}
function stat_out(s: Stat): number {
  return (
    (((Math.imul(s.mx, 2654435761) >>> 0) ^
      ((s.hi + Math.imul(s.lo, 340573321)) >>> 0)) +
      Math.imul(s.ok, 2246822519)) >>>
    0
  );
}

const t = tree_bsort(SIZE, 0, 0);
console.log(stat_out(tree_scan(SIZE, t)));
