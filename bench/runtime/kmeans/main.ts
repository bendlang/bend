// Native TS translation of main.bend: k-means with random
// restarts; stats trees live in a typed-array arena (u32 indices,
// same representation as the C twin).
const STATS_LEAF = 0,
  STATS_NODE = 1;
let arena_tag = new Uint8Array(1 << 16),
  arena_a = new Uint32Array(1 << 16),
  arena_b = new Uint32Array(1 << 16),
  arena_c = new Uint32Array(1 << 16),
  arena_len = 0;

function stats_push(tag: number, a: number, b: number, c: number): number {
  if (arena_len === arena_tag.length) {
    const n = arena_tag.length * 2;
    const t2 = new Uint8Array(n),
      a2 = new Uint32Array(n),
      b2 = new Uint32Array(n),
      c2 = new Uint32Array(n);
    t2.set(arena_tag);
    a2.set(arena_a);
    b2.set(arena_b);
    c2.set(arena_c);
    arena_tag = t2;
    arena_a = a2;
    arena_b = b2;
    arena_c = c2;
  }
  const i = arena_len++;
  arena_tag[i] = tag;
  arena_a[i] = a;
  arena_b[i] = b;
  arena_c[i] = c;
  return i;
}

function word_prng(x: number): number {
  x = (x ^ (x << 13)) >>> 0;
  x = (x ^ (x >>> 17)) >>> 0;
  return (x ^ (x << 5)) >>> 0;
}

function value_select(t: number, x: number, y: number): number {
  return t ? y : x;
}

function value_min(a: number, b: number): number {
  return value_select(a < b ? 1 : 0, b, a);
}

function point_distance(x: number, y: number, c: number, k: number): number {
  const cx = c & 65535,
    cy = c >>> 16,
    dx = value_select(x < cx ? 1 : 0, (x - cx) >>> 0, (cx - x) >>> 0),
    dy = value_select(y < cy ? 1 : 0, (y - cy) >>> 0, (cy - y) >>> 0);
  return ((((dx * dx + dy * dy) << 3) | k) >>> 0);
}

function stats_zip(x: number, y: number): number {
  const tx = arena_tag[x],
    ty = arena_tag[y];
  if (tx === STATS_LEAF && ty === STATS_LEAF)
    return stats_push(
      STATS_LEAF,
      (arena_a[x] + arena_a[y]) >>> 0,
      (arena_b[x] + arena_b[y]) >>> 0,
      (arena_c[x] + arena_c[y]) >>> 0,
    );
  if (tx === STATS_LEAF) return x;
  if (ty === STATS_LEAF) return x;
  const l = stats_zip(arena_a[x], arena_a[y]);
  const r = stats_zip(arena_b[x], arena_b[y]);
  return stats_push(STATS_NODE, l, r, 0);
}

function stats_chunk(i: number, c: Uint32Array): number {
  const sx = new Uint32Array(8),
    sy = new Uint32Array(8),
    nn = new Uint32Array(8);
  for (let j = 64; j; j--) {
    const h = word_prng(Math.imul((i + j) >>> 0, 2654435761) >>> 0),
      x = h & 1023,
      y = (h >>> 16) & 1023;
    const b =
      value_min(
        value_min(
          value_min(point_distance(x, y, c[0], 0), point_distance(x, y, c[1], 1)),
          value_min(point_distance(x, y, c[2], 2), point_distance(x, y, c[3], 3)),
        ),
        value_min(
          value_min(point_distance(x, y, c[4], 4), point_distance(x, y, c[5], 5)),
          value_min(point_distance(x, y, c[6], 6), point_distance(x, y, c[7], 7)),
        ),
      ) & 7;
    sx[b] += x;
    sy[b] += y;
    nn[b]++;
  }
  const q: number[] = [];
  for (let k = 0; k < 8; k++) q.push(stats_push(STATS_LEAF, sx[k], sy[k], nn[k]));
  return stats_push(
    STATS_NODE,
    stats_push(STATS_NODE, stats_push(STATS_NODE, q[0], q[1], 0), stats_push(STATS_NODE, q[2], q[3], 0), 0),
    stats_push(STATS_NODE, stats_push(STATS_NODE, q[4], q[5], 0), stats_push(STATS_NODE, q[6], q[7], 0), 0),
    0,
  );
}

function stats_fold(d: number, i: number, c: Uint32Array): number {
  if (d === 0) return stats_chunk(i, c);
  const x = stats_fold(d - 1, i, c);
  const y = stats_fold(d - 1, (i + (64 << (d - 1))) >>> 0, c);
  return stats_zip(x, y);
}

function stats_centroid(s: number, old: number): number {
  if (arena_tag[s] === STATS_NODE) return old;
  const n = arena_c[s],
    m = n ? n : 1,
    next = (Math.floor(arena_a[s] / m) | (Math.floor(arena_b[s] / m) << 16)) >>> 0;
  return n ? next : old;
}

function stats_split(s: number, out: number[], at: number): void {
  if (arena_tag[s] === STATS_NODE) {
    out[at] = arena_a[s];
    out[at + 1] = arena_b[s];
  } else {
    out[at] = s;
    out[at + 1] = stats_push(STATS_LEAF, 0, 0, 0);
  }
}

function centroids_step(d: number, c: Uint32Array): void {
  arena_len = 0;
  const root = stats_fold(d - 6, 0, c),
    p = [0, 0],
    q = [0, 0, 0, 0],
    z = [0, 0, 0, 0, 0, 0, 0, 0];
  stats_split(root, p, 0);
  stats_split(p[0], q, 0);
  stats_split(p[1], q, 2);
  for (let i = 0; i < 4; i++) stats_split(q[i], z, 2 * i);
  for (let i = 0; i < 8; i++) c[i] = stats_centroid(z[i], c[i]);
}

function centroid_initial(k: number): number {
  const h = word_prng((12345 + k) >>> 0);
  return ((h & 1023) | (((h >>> 16) & 1023) << 16)) >>> 0;
}

function restart_run(r: number, d: number): number {
  const c = new Uint32Array(8);
  for (let k = 0; k < 8; k++) c[k] = centroid_initial(r * 8 + k + 1);
  for (let n = 0; n < 20; n++) centroids_step(d, c);
  let h = c[0];
  for (let k = 1; k < 8; k++) h = (Math.imul(h, 2654435761) + c[k]) >>> 0;
  return h;
}

function restart_batch(b: number, r: number, d: number): number {
  return b === 0
    ? restart_run(r, d)
    : (restart_batch(b - 1, r, d) + restart_batch(b - 1, r + (1 << (b - 1)), d)) >>> 0;
}

console.log(restart_batch(6, 0, 19));
