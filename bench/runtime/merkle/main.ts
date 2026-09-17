// TypeScript twin of main.bend: same Speck32/64 leaf stream,
// Merkle tree build, audit re-fold, scalar-prover proof extraction and
// proof verification, single-threaded.
class MtLeaf {
    h: number;
  constructor(h: number) {
    this.h = h;
  }
}
class MtNode {
    h: number;
  l: Mt;
  r: Mt;
  constructor(h: number, l: Mt, r: Mt) {
    this.h = h;
    this.l = l;
    this.r = r;
  }
}
type Mt = MtLeaf | MtNode;

class PathNil {}
class PathCons {
    side: number;
  sib: number;
  rest: Path;
  constructor(side: number, sib: number, rest: Path) {
    this.side = side;
    this.sib = sib;
    this.rest = rest;
  }
}
type Path = PathNil | PathCons;

const SIZE = 22;
const BLOCKS = 30;
const PROBE = 1337;

const ROUND_KEYS = new Uint16Array([
  256, 5394, 24957, 5208, 26905, 30690, 3209, 52443, 61418, 20019, 30452,
  22902, 61067, 56068, 17943, 62334, 34740, 36554, 60827, 14930, 33321, 60772,
]);
function round_key(index: number): number {
  return ROUND_KEYS[index < 21 ? index : 21];
}

// 22 Speck rounds over the 16-bit halves x, y
function speck_run(rounds: number, index: number, x: number, y: number) {
  while (rounds !== 0) {
    const nextX = (((((x >>> 7) | (x << 9)) & 65535) + y) & 65535) ^
      round_key(index);
    y = ((((y << 2) | (y >>> 14)) & 65535) ^ nextX) & 65535;
    x = nextX & 65535;
    index++;
    rounds--;
  }
  return (x | (y << 16)) >>> 0;
}

// one leaf: encrypt `count` counter blocks, chain the ciphertexts
function block_chain(count: number, block: number, acc: number): number {
  while (count !== 0) {
    const ciphertext = speck_run(22, 0, block & 65535, (block >>> 16) & 65535);
    acc = (Math.imul(acc, 2654435761) + ciphertext) >>> 0;
    block = (block + 1) >>> 0;
    count--;
  }
  return acc;
}
function leaf_hash(b: number): number {
  return block_chain(BLOCKS, Math.imul(b, BLOCKS) >>> 0, (b + 1) >>> 0);
}

// Merkle join: ARX mix of the two child hashes
function hash_join(left: number, right: number): number {
  const h = (Math.imul(left, 2654435761) ^ right) >>> 0;
  const h2 =
    (Math.imul((h + 2246822519) >>> 0, 2246822519) ^ (h >>> 13)) >>> 0;
  return (h2 ^ (h2 >>> 16)) >>> 0;
}

// the scalar prover: recompute a subtree hash without materializing it
function hash_tree(depth: number, block: number): number {
  if (depth === 0) return leaf_hash(block);
  const left = hash_tree(depth - 1, block);
  const right = hash_tree(depth - 1, (block + (1 << (depth - 1))) >>> 0);
  return hash_join(left, right);
}

// join two subtrees into a hashed node (peek the child hashes)
function mt_join(l: Mt, r: Mt): Mt {
  return new MtNode(hash_join(l.h, r.h), l, r);
}
// build the Merkle tree over blocks b .. b + 2^d - 1
function mt_build(d: number, b: number): Mt {
  if (d === 0) return new MtLeaf(leaf_hash(b));
  const l = mt_build(d - 1, b);
  const r = mt_build(d - 1, (b + (1 << (d - 1))) >>> 0);
  return mt_join(l, r);
}
// audit: re-fold the tree; any stored-hash mismatch perturbs the result
function mt_audit(t: Mt): number {
  if (t instanceof MtLeaf) return t.h;
  const x = mt_audit(t.l);
  const y = mt_audit(t.r);
  const m = hash_join(x, y);
  return (m + ((m ^ t.h) >>> 0)) >>> 0;
}

// Merkle proof for leaf k: per level, the side bit and the sibling hash
function path_gen(d: number, k: number, b: number): Path {
  if (d === 0) return new PathNil();
  const bit = (k >>> (d - 1)) & 1;
  const half = 1 << (d - 1);
  const sib = hash_tree(d - 1, bit === 0 ? (b + half) >>> 0 : b);
  const rest = path_gen(d - 1, k, bit === 0 ? b : (b + half) >>> 0);
  return new PathCons(bit, sib, rest);
}
// fold the proof back up from the leaf hash to a root hash
function path_verify(p: Path, lh: number): number {
  if (p instanceof PathNil) return lh;
  const hh = path_verify(p.rest, lh);
  return p.side === 0 ? hash_join(hh, p.sib) : hash_join(p.sib, hh);
}

const t = mt_build(SIZE, 0);
const root = mt_audit(t);
const prf = path_gen(SIZE, PROBE, 0);
console.log(hash_join(root, path_verify(prf, leaf_hash(PROBE))));
