// TypeScript twin of main.bend: a hash table with separate chaining
// over 2^S independent tables. Same xorshift key of the seed and draw
// index masked to 20 bits, same low-12-bit bucket, same walk (it
// stops at the found key; Bend's stops one node later), same head
// insert, same hit count, same position-weighted fold over the chain
// lengths, same sum over the table tree, wrapping-u32 numerics (imul
// + >>>0). A table is an array of 4096 bucket heads, each a linked
// chain of Node objects (monomorphic shape); the GC plays the role
// of the linear frees.
const TABLES = 11;
const KEYS = 16384;

const word_wrap = (value: number): number => value >>> 0;

class Node {
  k: number;
  next: Node | null;
  constructor(k: number, next: Node | null) {
    this.k = k;
    this.next = next;
  }
}

function word_prng(x: number): number {
  const b = word_wrap(x ^ (x << 13));
  const d = word_wrap(b ^ (b >>> 17));
  return word_wrap(d ^ (d << 5));
}

// a key: the hash of a seed and a draw index, masked to 20 bits
function draw_key(s: number, j: number): number {
  const mj = Math.imul(j + 1, 2654435761);
  const ms = Math.imul(s, 340573321);
  return word_prng(word_wrap(mj ^ ms)) & 1048575;
}

// the chain walk: 1 when the key is in the chain, stopping at it
function chain_has(c: Node | null, k: number): number {
  for (let n = c; n !== null; n = n.next) {
    if (n.k === k) {
      return 1;
    }
  }
  return 0;
}

// a chain's length
function chain_len(c: Node | null): number {
  let l = 0;
  for (let n = c; n !== null; n = n.next) {
    l++;
  }
  return l;
}

// one insert: a present key leaves the bucket untouched, an absent
// one is consed onto the chain
function table_ins(t: (Node | null)[], k: number): void {
  const b = k & 4095;
  if (!chain_has(t[b], k)) {
    t[b] = new Node(k, t[b]);
  }
}

// one table: D inserts from the table seed, D lookups from the second
// seed, then the bucket sweep: lengths summed (the distinct count) and
// mixed position-weighted, sealed with the hit count
function table_run(ti: number, d: number): number {
  const t: (Node | null)[] = new Array(4096).fill(null);
  const s = Math.imul(ti + 1, 2654435761) >>> 0;
  for (let j = 0; j < d; j++) {
    table_ins(t, draw_key(s, j));
  }
  const s2 = word_prng(s);
  let hits = 0;
  for (let j = 0; j < d; j++) {
    const k = draw_key(s2, j);
    hits += chain_has(t[k & 4095], k);
  }
  let cnt = 0;
  let acc = 0;
  for (let i = 0; i < 4096; i++) {
    const l = chain_len(t[i]);
    cnt = word_wrap(cnt + l);
    acc = word_wrap(Math.imul(acc, 2654435761) ^ Math.imul(l, i + 3));
  }
  const sealed = word_wrap(acc ^ Math.imul(hits, 2654435761));
  return word_wrap(sealed + Math.imul(cnt, 340573321));
}

// batch tree over the table index space: table checksums sum up
function batch_run(p: number, t: number, d: number): number {
  if (p === 0) {
    return table_run(t, d);
  }
  const a = batch_run(p - 1, t, d);
  const b = batch_run(p - 1, word_wrap(t + (1 << (p - 1))), d);
  return word_wrap(a + b);
}

console.log(batch_run(TABLES, 0, KEYS));
