// Native TypeScript twin of main.bend: Levenshtein edit distance by
// dynamic programming, single-threaded, 1-to-1 with the Bend program:
// the same xorshift symbol streams (sequences are Uint8Arrays), the
// same two rolling Uint32Array rows swapping roles after every row,
// the same min chain and cost test per cell, and the same checksum
// fold over the pair index space (imul + >>>0 for wrapping u32).
const DEPTH = 15;
const N = 256;

function word_prng(x: number): number {
  const b = (x ^ (x << 13)) >>> 0;
  const d = (b ^ (b >>> 17)) >>> 0;
  return (d ^ (d << 5)) >>> 0;
}

// draw one sequence: step the stream, keep its low two bits
function seq_gen(s: number, x: Uint8Array): void {
  for (let k = 0; k < N; k++) {
    s = word_prng(s);
    x[k] = s & 3;
  }
}

// the DP: prev[j] = j at the start; row i reads a[i] once, writes
// cur[0] = i + 1, fills cur[1..N], then the rows swap roles
function edit_dist(a: Uint8Array, b: Uint8Array): number {
  let prev = new Uint32Array(N + 1);
  let cur = new Uint32Array(N + 1);
  for (let k = 0; k <= N; k++) {
    prev[k] = k;
  }
  for (let i = 0; i < N; i++) {
    const ai = a[i];
    cur[0] = i + 1;
    for (let j = 0; j < N; j++) {
      const cost = ai !== b[j] ? 1 : 0;
      cur[j + 1] =
        Math.min(Math.min(prev[j + 1] + 1, cur[j] + 1), prev[j] + cost);
    }
    const t = prev;
    prev = cur;
    cur = t;
  }
  return prev[N];
}

// one pair: seed from the hashed pair index, draw a and b, run the
// DP, mix the distance with the index
function pair_run(p: number): number {
  const a = new Uint8Array(N);
  const b = new Uint8Array(N);
  const s = Math.imul(p + 1, 2654435761) >>> 0;
  seq_gen(s, a);
  seq_gen(Math.imul(s, 340573321) >>> 0, b);
  return (Math.imul(edit_dist(a, b), 2654435761) ^ (p + 1)) >>> 0;
}

function batch_run(d: number, p: number): number {
  if (d === 0) {
    return pair_run(p);
  }
  const x = batch_run(d - 1, p);
  const y = batch_run(d - 1, (p + (1 << (d - 1))) >>> 0);
  return (x + y) >>> 0;
}

console.log(batch_run(DEPTH, 0));
