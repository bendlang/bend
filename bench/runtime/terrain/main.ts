// Native TypeScript twin of main.bend: procedural terrain tile
// pipeline. Same value-noise fill, in-place Gauss-Seidel relaxation sweeps
// with pass-salted roughening, 64-bin histogram and position-weighted
// folds, wrapping-u32 numerics (imul + >>>0; heightmaps are Uint32Arrays).
const word_wrap = (value: number): number => value >>> 0;

function word_prng(x: number): number {
  const b = word_wrap(x ^ (x << 13));
  const d = word_wrap(b ^ (b >>> 17));
  return word_wrap(d ^ (d << 5));
}

// lattice corner hash -> 0..255
function lattice_hash(gx: number, gz: number): number {
  return word_prng(word_wrap(Math.imul(gx, 2654435761) ^ Math.imul(gz, 340573321))) & 255;
}

// value noise at 8.8 fixed-point (x, z): bilinear lerp of 4 corner hashes
function terrain_ground(x: number, z: number): number {
  const gx = (x >>> 8) & 63;
  const gz = (z >>> 8) & 63;
  const fx = x & 255;
  const fz = z & 255;
  const gx1 = (gx + 1) & 63;
  const gz1 = (gz + 1) & 63;
  const h00 = lattice_hash(gx, gz);
  const h10 = lattice_hash(gx1, gz);
  const h01 = lattice_hash(gx, gz1);
  const h11 = lattice_hash(gx1, gz1);
  const t0 = (h00 * (256 - fx) + h10 * fx) >>> 8;
  const t1 = (h01 * (256 - fx) + h11 * fx) >>> 8;
  return (t0 * (256 - fz) + t1 * fz) >>> 8;
}

// noise-fill one tile: one write per cell
function tile_fill(ox: number, oz: number, h: Uint32Array): void {
  for (let i = 0; i < 4096; i++) {
    h[i] = terrain_ground(word_wrap((ox + (i & 63)) << 6), word_wrap((oz + (i >>> 6)) << 6));
  }
}

// one relaxation cell: 5 reads + 1 write, clamped neighbours,
// pass-salted 1-bit roughening
function erode_cell(i: number, p: number, h: Uint32Array): void {
  const xc = i & 63;
  const zc = i >>> 6;
  const hc = h[i];
  const hl = h[i - (xc > 0 ? 1 : 0)];
  const hr = h[i + (xc < 63 ? 1 : 0)];
  const hu = h[i - ((zc > 0 ? 1 : 0) << 6)];
  const hd = h[i + ((zc < 63 ? 1 : 0) << 6)];
  const rough = word_prng(word_wrap(i ^ word_wrap(Math.imul(p, 2654435761)))) & 1;
  h[i] = word_wrap(((word_wrap(hc * 4 + hl + hr + hu + hd)) >>> 3) + rough);
}

// one Gauss-Seidel sweep over the tile, ascending scan order
function tile_erode(p: number, h: Uint32Array): void {
  for (let i = 0; i < 4096; i++) {
    erode_cell(i, p, h);
  }
}

function tile_smooth(p: number, h: Uint32Array): void {
  while (p !== 0) {
    tile_erode(p, h);
    p--;
  }
}

// histogram fold: mix every bucket count, position-weighted
function hist_fold(g: Uint32Array, acc: number): number {
  for (let i = 0; i < 64; i++) {
    acc = word_wrap(Math.imul(acc, 2654435761) ^ word_wrap(Math.imul(g[i], i + 3)));
  }
  return acc;
}

// per cell: read the height, bump its histogram bucket, mix the height
function tile_hist(h: Uint32Array, g: Uint32Array, acc: number): number {
  for (let i = 0; i < 4096; i++) {
    const v = h[i];
    const b = (v >>> 2) & 63;
    g[b] = word_wrap(g[b] + 1);
    acc = word_wrap(Math.imul(acc, 2654435761) + Math.imul(v, i + 1));
  }
  return hist_fold(g, acc);
}

// one tile: fill, EPASS relaxation sweeps, histogram + fold
function tile_run(t: number, e: number): number {
  const h = new Uint32Array(4096);
  const g = new Uint32Array(64);
  const ox = word_wrap((t & 255) << 6);
  const oz = word_wrap((t >>> 8) << 6);
  tile_fill(ox, oz, h);
  tile_smooth(e, h);
  return tile_hist(h, g, word_wrap(t + 1));
}

function batch_run(d: number, t: number, e: number): number {
  if (d === 0) {
    return tile_run(t, e);
  }
  const a = batch_run(d - 1, t, e);
  const b = batch_run(d - 1, word_wrap(t + (1 << (d - 1))), e);
  return word_wrap(a + b);
}

console.log(batch_run(16, 0, 5));
