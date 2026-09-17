// Native TS translation of main.bend: histogram-equalized
// escape-time render, 4096x4096, signed 8.8 fixed point, ITERS
// branchless iterations per pixel (z freezes at escape).
const ITERS = 51,
  WIDTH = 4096;
const word_wrap = (x: number): number => x >>> 0;

function value_select(t: number, x: number, y: number): number {
  return t ? y : x;
}

// arithmetic shift right by 8 over two's-complement u32
function word_asr8(v: number): number {
  return word_wrap((v >>> 8) | value_select(v >>> 31, 0, 4278190080));
}

// ITERS branchless escape-time iterations: z steps while esc == 0 and
// freezes after, it counts the pre-escape iterations
function pixel_iterate(n: number, cr: number, ci: number): number {
  let zr = 0,
    zi = 0,
    esc = 0,
    it = 0;
  for (; n; n--) {
    const r2 = word_asr8(Math.imul(zr, zr) >>> 0);
    const i2 = word_asr8(Math.imul(zi, zi) >>> 0);
    const e2 = esc | (word_wrap(r2 + i2) > 1024 ? 1 : 0);
    const nzr = word_wrap(word_wrap(r2 - i2) + cr);
    const nzi = word_wrap(word_asr8(Math.imul(2, Math.imul(zr, zi)) >>> 0) + ci);
    zr = value_select(e2, nzr, zr);
    zi = value_select(e2, nzi, zi);
    esc = e2;
    it = it + (e2 === 0 ? 1 : 0);
  }
  return it;
}

// one pixel: viewport [-2, 1) x [-1.5, 1.5) over the WIDTH^2 grid
function pixel_escape(id: number): number {
  const cr = word_wrap(Math.floor(((id & (WIDTH - 1)) * 768) / WIDTH) - 512);
  const ci = word_wrap(Math.floor((Math.floor(id / WIDTH) * 768) / WIDTH) - 384);
  return pixel_iterate(ITERS, cr, ci);
}

// escape time -> one of 8 buckets, knob-stable
function pixel_bucket(it: number): number {
  const bq = Math.floor((it * 8) / ITERS);
  return value_select(bq > 7 ? 1 : 0, bq, 7);
}

const total = WIDTH * WIDTH;
const h = new Uint32Array(8);
for (let i = 0; i < total; i++) h[pixel_bucket(pixel_escape(i))]++;
const lut = new Uint32Array(8);
let c = 0;
for (let k = 0; k < 8; k++) {
  c = word_wrap(c + h[k]);
  lut[k] = c;
}
const cn = lut[7];
for (let k = 0; k < 8; k++) lut[k] = Math.floor((lut[k] * 255) / cn);
let mix = lut[0];
for (let k = 1; k < 8; k++) mix = word_wrap(Math.imul(mix, 2654435761) + lut[k]);
let r = 0;
for (let i = 0; i < total; i++) {
  const it = pixel_escape(i);
  const col = lut[pixel_bucket(it)];
  r = word_wrap(r + word_wrap(Math.imul(col, word_wrap(Math.imul(i, 2654435761) + 1)) + it));
}
console.log(word_wrap(Math.imul(mix, 2654435761) + r));
