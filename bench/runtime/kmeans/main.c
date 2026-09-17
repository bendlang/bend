#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

typedef enum StTag { SL, SN } StTag;
typedef struct St {
  uint32_t tag, a, b, c;
} St;
typedef struct Arena {
  St *at;
  size_t len, cap;
} Arena;
static uint32_t st_push(Arena *h, St s) {
  if (h->len == h->cap) {
    size_t n = h->cap ? h->cap * 2 : 1024;
    St *p = realloc(h->at, n * sizeof *p);
    if (!p)
      exit(2);
    h->at = p;
    h->cap = n;
  }
  h->at[h->len] = s;
  return (uint32_t)h->len++;
}
static uint32_t st_sl(Arena *h, uint32_t sx, uint32_t sy, uint32_t n) {
  return st_push(h, (St){SL, sx, sy, n});
}
static uint32_t st_sn(Arena *h, uint32_t l, uint32_t r) {
  return st_push(h, (St){SN, l, r, 0});
}
static uint32_t b2u(uint32_t b) { return b ? 1 : 0; }
static uint32_t prng(uint32_t x) {
  uint32_t b = x ^ (x << 13), d = b ^ (b >> 17);
  return d ^ (d << 5);
}
static uint32_t sel_go(uint32_t x, uint32_t y, uint32_t z) {
  return z ? x : y;
}
static uint32_t sel(uint32_t t, uint32_t x, uint32_t y) {
  return sel_go(x, y, t == 0);
}
static uint32_t min2(uint32_t a, uint32_t b) {
  return sel(b2u(a < b), b, a);
}
static uint32_t dst(uint32_t x, uint32_t y, uint32_t c, uint32_t k) {
  uint32_t cx = c & 65535, cy = c >> 16;
  uint32_t dx = sel(b2u(x < cx), x - cx, cx - x);
  uint32_t dy = sel(b2u(y < cy), y - cy, cy - y);
  return ((dx * dx + dy * dy) << 3) | k;
}
static uint32_t szip(Arena *h, uint32_t a, uint32_t b) {
  St p = h->at[a], q = h->at[b];
  if (p.tag == SL && q.tag == SL)
    return st_sl(h, p.a + q.a, p.b + q.b, p.c + q.c);
  if (p.tag == SL)
    return a;
  if (q.tag == SL)
    return a;
  uint32_t l = szip(h, p.a, q.a), r = szip(h, p.b, q.b);
  return st_sn(h, l, r);
}
static uint32_t chunk(Arena *h, uint32_t j, uint32_t i, uint32_t c0,
                      uint32_t c1, uint32_t c2, uint32_t c3, uint32_t c4,
                      uint32_t c5, uint32_t c6, uint32_t c7, uint32_t s0x,
                      uint32_t s0y, uint32_t s0n, uint32_t s1x, uint32_t s1y,
                      uint32_t s1n, uint32_t s2x, uint32_t s2y, uint32_t s2n,
                      uint32_t s3x, uint32_t s3y, uint32_t s3n, uint32_t s4x,
                      uint32_t s4y, uint32_t s4n, uint32_t s5x, uint32_t s5y,
                      uint32_t s5n, uint32_t s6x, uint32_t s6y, uint32_t s6n,
                      uint32_t s7x, uint32_t s7y, uint32_t s7n) {
  if (!j) {
    uint32_t q0 = st_sl(h, s0x, s0y, s0n), q1 = st_sl(h, s1x, s1y, s1n);
    uint32_t q2 = st_sl(h, s2x, s2y, s2n), q3 = st_sl(h, s3x, s3y, s3n);
    uint32_t q4 = st_sl(h, s4x, s4y, s4n), q5 = st_sl(h, s5x, s5y, s5n);
    uint32_t q6 = st_sl(h, s6x, s6y, s6n), q7 = st_sl(h, s7x, s7y, s7n);
    return st_sn(h, st_sn(h, st_sn(h, q0, q1), st_sn(h, q2, q3)),
                 st_sn(h, st_sn(h, q4, q5), st_sn(h, q6, q7)));
  }
  uint32_t hh = prng((i + j) * 2654435761u);
  uint32_t xx = hh & 1023, yy = (hh >> 16) & 1023;
  uint32_t bk = min2(min2(min2(dst(xx, yy, c0, 0), dst(xx, yy, c1, 1)),
                          min2(dst(xx, yy, c2, 2), dst(xx, yy, c3, 3))),
                     min2(min2(dst(xx, yy, c4, 4), dst(xx, yy, c5, 5)),
                          min2(dst(xx, yy, c6, 6), dst(xx, yy, c7, 7)))) &
                7;
  uint32_t m0 = b2u(bk == 0), m1 = b2u(bk == 1), m2 = b2u(bk == 2),
           m3 = b2u(bk == 3), m4 = b2u(bk == 4), m5 = b2u(bk == 5),
           m6 = b2u(bk == 6), m7 = b2u(bk == 7);
  return chunk(h, j - 1, i, c0, c1, c2, c3, c4, c5, c6, c7,
               s0x + m0 * xx, s0y + m0 * yy, s0n + m0,
               s1x + m1 * xx, s1y + m1 * yy, s1n + m1,
               s2x + m2 * xx, s2y + m2 * yy, s2n + m2,
               s3x + m3 * xx, s3y + m3 * yy, s3n + m3,
               s4x + m4 * xx, s4y + m4 * yy, s4n + m4,
               s5x + m5 * xx, s5y + m5 * yy, s5n + m5,
               s6x + m6 * xx, s6y + m6 * yy, s6n + m6,
               s7x + m7 * xx, s7y + m7 * yy, s7n + m7);
}
static uint32_t pfold(Arena *h, uint32_t d, uint32_t i, uint32_t c0,
                      uint32_t c1, uint32_t c2, uint32_t c3, uint32_t c4,
                      uint32_t c5, uint32_t c6, uint32_t c7) {
  if (!d)
    return chunk(h, 64, i, c0, c1, c2, c3, c4, c5, c6, c7, 0, 0, 0, 0, 0, 0, 0,
                 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
  uint32_t a = pfold(h, d - 1, i, c0, c1, c2, c3, c4, c5, c6, c7);
  uint32_t b = pfold(h, d - 1, i + (64u << (d - 1)), c0, c1, c2, c3, c4, c5,
                     c6, c7);
  return szip(h, a, b);
}
static uint32_t cnew(Arena *h, uint32_t s, uint32_t old) {
  St x = h->at[s];
  if (x.tag == SL) {
    uint32_t nn = x.c;
    uint32_t mm = sel(b2u(nn == 0), nn, 1);
    return sel(b2u(nn == 0), x.a / mm | (x.b / mm) << 16, old);
  }
  return old;
}
typedef struct Cs {
  uint32_t c0, c1, c2, c3, c4, c5, c6, c7;
} Cs;
static Cs step_fin(Arena *h, uint32_t c0, uint32_t c1, uint32_t c2,
                   uint32_t c3, uint32_t c4, uint32_t c5, uint32_t c6,
                   uint32_t c7, uint32_t t) {
  St r = h->at[t];
  if (r.tag == SN) {
    St rl = h->at[r.a], rr = h->at[r.b];
    if (rl.tag == SN && rr.tag == SN) {
      St a = h->at[rl.a], b = h->at[rl.b], c = h->at[rr.a], d = h->at[rr.b];
      if (a.tag == SN && b.tag == SN && c.tag == SN && d.tag == SN)
        return (Cs){cnew(h, a.a, c0), cnew(h, a.b, c1), cnew(h, b.a, c2),
                    cnew(h, b.b, c3), cnew(h, c.a, c4), cnew(h, c.b, c5),
                    cnew(h, d.a, c6), cnew(h, d.b, c7)};
    }
  }
  return (Cs){c0, c1, c2, c3, c4, c5, c6, c7};
}
static Cs step(Arena *h, uint32_t d, uint32_t c0, uint32_t c1, uint32_t c2,
               uint32_t c3, uint32_t c4, uint32_t c5, uint32_t c6,
               uint32_t c7) {
  h->len = 0;
  uint32_t t = pfold(h, d - 6, 0, c0, c1, c2, c3, c4, c5, c6, c7);
  return step_fin(h, c0, c1, c2, c3, c4, c5, c6, c7, t);
}
static uint32_t loop(Arena *h, uint32_t r, uint32_t d, Cs cs) {
  if (!r) {
    uint32_t m1 = cs.c0 * 2654435761u + cs.c1;
    uint32_t m2 = m1 * 2654435761u + cs.c2;
    uint32_t m3 = m2 * 2654435761u + cs.c3;
    uint32_t m4 = m3 * 2654435761u + cs.c4;
    uint32_t m5 = m4 * 2654435761u + cs.c5;
    uint32_t m6 = m5 * 2654435761u + cs.c6;
    return m6 * 2654435761u + cs.c7;
  }
  return loop(h, r - 1, d,
              step(h, d, cs.c0, cs.c1, cs.c2, cs.c3, cs.c4, cs.c5, cs.c6,
                   cs.c7));
}
static uint32_t cini(uint32_t k) {
  uint32_t hh = prng(12345 + k);
  return (hh & 1023) | ((hh >> 16) & 1023) << 16;
}
static uint32_t rst(Arena *h, uint32_t r, uint32_t d) {
  uint32_t rr = r * 8;
  return loop(h, 20, d,
              (Cs){cini(rr + 1), cini(rr + 2), cini(rr + 3), cini(rr + 4),
                   cini(rr + 5), cini(rr + 6), cini(rr + 7), cini(rr + 8)});
}
static uint32_t rbatch(Arena *h, uint32_t b, uint32_t r, uint32_t d) {
  if (!b)
    return rst(h, r, d);
  uint32_t x = rbatch(h, b - 1, r, d);
  uint32_t y = rbatch(h, b - 1, r + (1u << (b - 1)), d);
  return x + y;
}
static uint32_t size(void) { return 19; }
int main(void) {
  Arena h = {0};
  printf("%u\n", rbatch(&h, 6, 0, size()));
  free(h.at);
}
