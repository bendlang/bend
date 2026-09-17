// TypeScript twin of main.bend: same trie sort (gen ->
// to_map/merge -> to_arr) and Chk verification scan, single-threaded.
// ADT nodes are class instances (monomorphic shapes); the GC plays the
// role of the linear frees.
class ArrEmpty {}
class ArrSingle {
    v: number;
  constructor(v: number) {
    this.v = v;
  }
}
class ArrConcat {
    l: Arr;
  r: Arr;
  constructor(l: Arr, r: Arr) {
    this.l = l;
    this.r = r;
  }
}
type Arr = ArrEmpty | ArrSingle | ArrConcat;

class MapFree {}
class MapBusy {}
class MapNode {
    l: MapTree;
  r: MapTree;
  constructor(l: MapTree, r: MapTree) {
    this.l = l;
    this.r = r;
  }
}
type MapTree = MapFree | MapBusy | MapNode;

type Chk = {
  nil: number;
  lo: number;
  hi: number;
  ok: number;
  cnt: number;
  sum: number;
};

const DEPTH = 22;

function word_prng(x: number): number {
  const b = (x ^ (x << 13)) >>> 0;
  const d = (b ^ (b >>> 17)) >>> 0;
  return (d ^ (d << 5)) >>> 0;
}
function word_key(i: number): number {
  return word_prng(Math.imul(i + 1, 2654435761) >>> 0) & 16777215;
}

function map_merge(a: MapTree, b: MapTree): MapTree {
  if (a instanceof MapFree) return b;
  if (b instanceof MapFree) return a;
  if (a instanceof MapBusy || b instanceof MapBusy) return new MapBusy();
  const an = a as MapNode;
  const bn = b as MapNode;
  return new MapNode(map_merge(an.l, bn.l), map_merge(an.r, bn.r));
}
function arr_generate(n: number, x: number): Arr {
  if (n === 0) return new ArrSingle(word_key(x));
  return new ArrConcat(
    arr_generate(n - 1, (x * 2) >>> 0),
    arr_generate(n - 1, (x * 2 + 1) >>> 0),
  );
}
function map_swap_bits(n: number, x0: MapTree, x1: MapTree): MapTree {
  return n === 0 ? new MapNode(x0, x1) : new MapNode(x1, x0);
}
function map_radix(i: number, n: number, k: number, r: MapTree): MapTree {
  while (i) {
    r = map_swap_bits(n & k, r, new MapFree());
    k = (k * 2) >>> 0;
    i--;
  }
  return r;
}
function arr_to_map(a: Arr): MapTree {
  if (a instanceof ArrEmpty) return new MapFree();
  if (a instanceof ArrSingle) return map_radix(24, a.v, 1, new MapBusy());
  const c = a as ArrConcat;
  return map_merge(arr_to_map(c.l), arr_to_map(c.r));
}
function map_to_arr(m: MapTree, k: number): Arr {
  if (m instanceof MapFree) return new ArrEmpty();
  if (m instanceof MapBusy) return new ArrSingle(k);
  const n = m as MapNode;
  return new ArrConcat(
    map_to_arr(n.l, (k * 2) >>> 0),
    map_to_arr(n.r, (k * 2 + 1) >>> 0),
  );
}

function chk_join(a: Chk, b: Chk): Chk {
  if (a.nil) return b;
  if (b.nil) return a;
  return {
    nil: 0,
    lo: a.lo,
    hi: b.hi,
    ok: a.ok & b.ok & (a.hi < b.lo ? 1 : 0),
    cnt: (a.cnt + b.cnt) >>> 0,
    sum: (a.sum + b.sum) >>> 0,
  };
}
function arr_chk(a: Arr): Chk {
  if (a instanceof ArrEmpty)
    return { nil: 1, lo: 0, hi: 0, ok: 0, cnt: 0, sum: 0 };
  if (a instanceof ArrSingle)
    return { nil: 0, lo: a.v, hi: a.v, ok: 1, cnt: 1, sum: a.v };
  const c = a as ArrConcat;
  return chk_join(arr_chk(c.l), arr_chk(c.r));
}
function chk_out(c: Chk): number {
  if (c.nil) return 0;
  return (
    ((((c.sum + Math.imul(c.cnt, 2654435761)) >>> 0) ^
      ((c.hi + Math.imul(c.lo, 340573321)) >>> 0)) +
      Math.imul(c.ok, 2246822519)) >>>
    0
  );
}

function arr_sort(a: Arr): Arr {
  return map_to_arr(arr_to_map(a), 0);
}

console.log(chk_out(arr_chk(arr_sort(arr_generate(DEPTH, 0)))));
