// Native C translation of main.bend: histogram-equalized
// escape-time render, 4096x4096, signed 8.8 fixed point, ITERS
// branchless iterations per pixel (z freezes at escape).
#include <stdint.h>
#include <stdio.h>

typedef struct { uint32_t h0, h1, h2, h3, h4, h5, h6, h7; } Hs;
typedef struct { uint32_t k0, k1, k2, k3, k4, k5, k6, k7; } Lut;

// Bool is already 0/1
static uint32_t b2u(uint32_t b) {
  return b;
}

static uint32_t sel_go(uint32_t x, uint32_t y, uint32_t z) {
  return z ? x : y;
}

static uint32_t sel(uint32_t t, uint32_t x, uint32_t y) {
  return sel_go(x, y, t == 0);
}

// arithmetic shift right by 8 over two's-complement u32
static uint32_t asr8(uint32_t v) {
  return (uint32_t)((int32_t)v >> 8);
}

// ITERS branchless escape-time iterations: z steps while esc == 0 and
// freezes after (sel), it counts the pre-escape iterations
static uint32_t mit(uint32_t n, uint32_t cr, uint32_t ci, uint32_t zr, uint32_t zi, uint32_t esc, uint32_t it) {
  if (n == 0)
    return it;
  uint32_t r2 = asr8(zr * zr);
  uint32_t i2 = asr8(zi * zi);
  uint32_t e2 = esc | b2u(r2 + i2 > 1024);
  uint32_t nzr = r2 - i2 + cr;
  uint32_t nzi = asr8(2 * (zr * zi)) + ci;
  uint32_t sr = sel(e2, nzr, zr);
  uint32_t si = sel(e2, nzi, zi);
  return mit(n - 1, cr, ci, sr, si, e2, it + b2u(e2 == 0));
}

// one pixel: viewport [-2, 1) x [-1.5, 1.5) over the 4096x4096 grid
static uint32_t pix(uint32_t id, uint32_t tn) {
  uint32_t cr = (id & 4095) * 768 / 4096 - 512;
  uint32_t ci = (id >> 12) * 768 / 4096 - 384;
  return mit(tn, cr, ci, 0, 0, 0, 0);
}

// escape time -> one of 8 buckets, knob-stable: (it*8)/ITERS clamped
static uint32_t bkt(uint32_t it, uint32_t tn) {
  uint32_t bq = it * 8 / tn;
  return sel(b2u(bq > 7), bq, 7);
}

// pass-1 leaf: 64 pixels bucketed into 8 scalar counters
static Hs hchunk(uint32_t j, uint32_t i, uint32_t tn, uint32_t h0, uint32_t h1, uint32_t h2, uint32_t h3, uint32_t h4, uint32_t h5, uint32_t h6, uint32_t h7) {
  if (j == 0)
    return (Hs){h0, h1, h2, h3, h4, h5, h6, h7};
  uint32_t p = j - 1;
  uint32_t it = pix(i + p, tn);
  uint32_t bk = bkt(it, tn);
  uint32_t m0 = b2u(bk == 0);
  uint32_t m1 = b2u(bk == 1);
  uint32_t m2 = b2u(bk == 2);
  uint32_t m3 = b2u(bk == 3);
  uint32_t m4 = b2u(bk == 4);
  uint32_t m5 = b2u(bk == 5);
  uint32_t m6 = b2u(bk == 6);
  uint32_t m7 = b2u(bk == 7);
  return hchunk(p, i, tn, h0 + m0, h1 + m1, h2 + m2, h3 + m3, h4 + m4, h5 + m5, h6 + m6, h7 + m7);
}

static Hs hzip(Hs a, Hs b) {
  return (Hs){a.h0 + b.h0, a.h1 + b.h1, a.h2 + b.h2, a.h3 + b.h3, a.h4 + b.h4, a.h5 + b.h5, a.h6 + b.h6, a.h7 + b.h7};
}

static Hs hfold(uint32_t d, uint32_t i, uint32_t tn) {
  if (d == 0)
    return hchunk(64, i, tn, 0, 0, 0, 0, 0, 0, 0, 0);
  uint32_t p = d - 1;
  Hs a = hfold(p, i, tn);
  Hs b = hfold(p, i + (64u << p), tn);
  return hzip(a, b);
}

// histogram equalization: LUT k = cdf(k) scaled to 0..255
static Lut cdf(Hs h) {
  uint32_t c0 = h.h0;
  uint32_t c1 = c0 + h.h1;
  uint32_t c2 = c1 + h.h2;
  uint32_t c3 = c2 + h.h3;
  uint32_t c4 = c3 + h.h4;
  uint32_t c5 = c4 + h.h5;
  uint32_t c6 = c5 + h.h6;
  uint32_t c7 = c6 + h.h7;
  return (Lut){c0 * 255 / c7, c1 * 255 / c7, c2 * 255 / c7, c3 * 255 / c7,
               c4 * 255 / c7, c5 * 255 / c7, c6 * 255 / c7, c7 * 255 / c7};
}

// pass-2 leaf: recompute the pixel, recolor through the LUT (branchless
// masked pick), weight by a position hash
static uint32_t rpix(uint32_t i, uint32_t tn, uint32_t k0, uint32_t k1, uint32_t k2, uint32_t k3, uint32_t k4, uint32_t k5, uint32_t k6, uint32_t k7) {
  uint32_t it = pix(i, tn);
  uint32_t bk = bkt(it, tn);
  uint32_t col = b2u(bk == 0) * k0 + (b2u(bk == 1) * k1 + (b2u(bk == 2) * k2 + (b2u(bk == 3) * k3 +
                 (b2u(bk == 4) * k4 + (b2u(bk == 5) * k5 + (b2u(bk == 6) * k6 + b2u(bk == 7) * k7))))));
  return col * (i * 2654435761u + 1) + it;
}

static uint32_t rcol(uint32_t d, uint32_t i, uint32_t tn, uint32_t k0, uint32_t k1, uint32_t k2, uint32_t k3, uint32_t k4, uint32_t k5, uint32_t k6, uint32_t k7) {
  if (d == 0)
    return rpix(i, tn, k0, k1, k2, k3, k4, k5, k6, k7);
  uint32_t p = d - 1;
  uint32_t a = rcol(p, i, tn, k0, k1, k2, k3, k4, k5, k6, k7);
  uint32_t b = rcol(p, i + (1u << p), tn, k0, k1, k2, k3, k4, k5, k6, k7);
  return a + b;
}

static uint32_t rend_mix(uint32_t hd, uint32_t tn, Lut lut) {
  uint32_t q0 = lut.k0;
  uint32_t q1 = lut.k1;
  uint32_t q2 = lut.k2;
  uint32_t q3 = lut.k3;
  uint32_t q4 = lut.k4;
  uint32_t q5 = lut.k5;
  uint32_t q6 = lut.k6;
  uint32_t q7 = lut.k7;
  uint32_t m1 = q0 * 2654435761u + q1;
  uint32_t m2 = m1 * 2654435761u + q2;
  uint32_t m3 = m2 * 2654435761u + q3;
  uint32_t m4 = m3 * 2654435761u + q4;
  uint32_t m5 = m4 * 2654435761u + q5;
  uint32_t m6 = m5 * 2654435761u + q6;
  uint32_t m7 = m6 * 2654435761u + q7;
  uint32_t r = rcol(hd + 6, 0, tn, q0, q1, q2, q3, q4, q5, q6, q7);
  return m7 * 2654435761u + r;
}

static uint32_t rend(uint32_t hd, uint32_t tn) {
  return rend_mix(hd, tn, cdf(hfold(hd, 0, tn)));
}

static uint32_t its(void) {
  return 51;
}

// small: rend(2, 7) expect 887240761; big rend(18, its()) expect 3101455856
int main(void) {
  printf("%u\n", rend(18, its()));
  return 0;
}
