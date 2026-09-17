// TypeScript twin of main.bend: breadth-first search over 2^DEPTH
// independent 32x32 grid mazes, single-threaded, 1-to-1 with the Bend
// program: same seed and wall hash, a Uint32Array grid (1 open, 0
// wall), a Uint32Array queue with head and tail, a Uint32Array distance
// map seeded unseen, the textbook pop loop with four bounds-checked
// neighbour looks, and the same position-weighted fold sealed by the
// reached count (imul + >>>0 for the wrapping-u32 numerics); leaf
// checksums sum up the batch recursion.
const DEPTH = 19;
const CELLS = 1024;
const UNSEEN = 0xffffffff;

class Bfs {
  g = new Uint32Array(CELLS);
  q = new Uint32Array(CELLS);
  d = new Uint32Array(CELLS);
  head = 0;
  tail = 0;
}

function word_prng(x: number): number {
  const b = (x ^ (x << 13)) >>> 0;
  const d = (b ^ (b >>> 17)) >>> 0;
  return (d ^ (d << 5)) >>> 0;
}

// 1 when cell c of the maze seeded s is open: the start always, any
// other cell when its hash mod 100 is 30 or more (30% walls)
function cell_open(s: number, c: number): number {
  const h = word_prng((s ^ Math.imul(c + 1, 340573321)) >>> 0);
  return c === 0 || h % 100 >= 30 ? 1 : 0;
}

// one neighbour n at distance v: skip it out of bounds, a wall or
// seen; else stamp its distance and push it
function bfs_look(b: Bfs, n: number, v: number, inb: boolean): void {
  if (inb && b.g[n] !== 0 && b.d[n] === UNSEEN) {
    b.d[n] = v;
    b.q[b.tail] = n;
    b.tail += 1;
  }
}

// one pop: the head cell and its distance, then its four neighbours
function bfs_pop(b: Bfs): void {
  const c = b.q[b.head];
  const v = (b.d[c] + 1) >>> 0;
  const x = c & 31;
  const y = c >>> 5;
  b.head += 1;
  bfs_look(b, (c - 1) >>> 0, v, x > 0);
  bfs_look(b, c + 1, v, x < 31);
  bfs_look(b, (c - 32) >>> 0, v, y > 0);
  bfs_look(b, c + 32, v, y < 31);
}

// the leaf checksum: a reached cell mixes its distance position-
// weighted and counts one; the count seals the mix
function bfs_fold(b: Bfs): number {
  let acc = 0;
  let cnt = 0;
  for (let c = 0; c < CELLS; c++) {
    const v = b.d[c];
    const hit = v !== UNSEEN ? 1 : 0;
    acc = (Math.imul(acc, 2654435761) ^ (hit ? Math.imul(v, c + 1) : 0)) >>> 0;
    cnt = (cnt + hit) >>> 0;
  }
  return (acc ^ Math.imul(cnt, 2246822519)) >>> 0;
}

// one maze: fill the grid, seed the search with cell 0 at distance 0,
// search, fold
function maze_run(m: number): number {
  const b = new Bfs();
  const s = Math.imul(m + 1, 2654435761) >>> 0;
  for (let c = 0; c < CELLS; c++) {
    b.g[c] = cell_open(s, c);
    b.d[c] = UNSEEN;
  }
  b.d[0] = 0;
  b.head = 0;
  b.tail = 1;
  while (b.head < b.tail) {
    bfs_pop(b);
  }
  return bfs_fold(b);
}

function batch_run(k: number, i: number): number {
  if (k === 0) {
    return maze_run(i);
  }
  const a = batch_run(k - 1, i);
  const b = batch_run(k - 1, (i + (1 << (k - 1))) >>> 0);
  return (a + b) >>> 0;
}

console.log(batch_run(DEPTH, 0));
