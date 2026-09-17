// Native C translation of main.bend: chaotic three-body ensemble,
// f32, Plummer-softened, symplectic Euler; 2^(SY+3) seeded systems, ST
// steps each; checksum mixes the outcome histogram and digest sum.
// One C function per Bend function; Bend's fl(n,d) rationals appear as
// the equal f32 literals, b2u/sel as the ternary they encode.
// Build: cc -O3 main.c -lm. Expected at SY=17, ST=300: 3516450380 with
// -ffp-contract=off (Bend's uncontracted f32 bits); plain -O3 fuses
// a*b+c into fma and prints 1424365735.
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#ifndef SY
#define SY 17
#endif
#ifndef ST
#define ST 300
#endif

typedef struct {
  uint32_t h0, h1, h2, h3, h4, h5, h6, h7, cs;
} Hs;

typedef struct {
  uint32_t cs, eb;
} V2;

static uint32_t prng(uint32_t x) {
  uint32_t b = x ^ (x << 13), d = b ^ (b >> 17);
  return d ^ (d << 5);
}

// F32.to_u32: truncate toward zero; NaN, negative, or >= 2^32 -> 0
static uint32_t f32_to_u32(float f) {
  uint32_t b;
  memcpy(&b, &f, 4);
  if (b >> 31)
    return 0;
  uint32_t e = (b >> 23) & 0xff;
  if (e < 127 || e >= 159)
    return 0;
  uint32_t m = (b & 0x7fffff) | 0x800000;
  return e >= 150 ? m << (e - 150) : m >> (150 - e);
}

// ST integration steps over one system's 21 f32 state registers; at 0,
// digest: position hash + total energy (kinetic - softened potential)
// bucketed by its bound magnitude
static V2 loop3(uint32_t s, float x0, float y0, float z0, float x1, float y1,
                float z1, float x2, float y2, float z2, float vx0, float vy0,
                float vz0, float vx1, float vy1, float vz1, float vx2,
                float vy2, float vz2, float m0, float m1, float m2) {
  if (s == 0) {
    float s0 = vx0 * vx0 + (vy0 * vy0 + vz0 * vz0);
    float s1 = vx1 * vx1 + (vy1 * vy1 + vz1 * vz1);
    float s2 = vx2 * vx2 + (vy2 * vy2 + vz2 * vz2);
    float k0 = (0.5f * m0) * s0;
    float k1 = (0.5f * m1) * s1;
    float k2 = (0.5f * m2) * s2;
    float ke = k0 + (k1 + k2);
    float ax = x1 - x0, ay = y1 - y0, az = z1 - z0;
    float da = (ax * ax + (ay * ay + az * az)) + 0.05f;
    float bx = x2 - x0, by = y2 - y0, bz = z2 - z0;
    float db = (bx * bx + (by * by + bz * bz)) + 0.05f;
    float cx = x2 - x1, cy = y2 - y1, cz = z2 - z1;
    float dc = (cx * cx + (cy * cy + cz * cz)) + 0.05f;
    float pa = (m0 * m1) / sqrtf(da);
    float pb = (m0 * m2) / sqrtf(db);
    float pc = (m1 * m2) / sqrtf(dc);
    float pe = pa + (pb + pc);
    float e = ke - pe;
    uint32_t nb = f32_to_u32(0.0f - e);
    uint32_t eb = nb > 7 ? 7 : nb;
    uint32_t w0 = f32_to_u32((x0 + 8.0f) * 65536.0f) * 31 +
                  f32_to_u32((y0 + 8.0f) * 65536.0f);
    uint32_t w1 = f32_to_u32((x1 + 8.0f) * 65536.0f) * 31 +
                  f32_to_u32((y1 + 8.0f) * 65536.0f);
    uint32_t w2 = f32_to_u32((x2 + 8.0f) * 65536.0f) * 31 +
                  f32_to_u32((y2 + 8.0f) * 65536.0f);
    uint32_t w3 = f32_to_u32((z0 + 8.0f) * 65536.0f) * 31 +
                  f32_to_u32((z1 + 8.0f) * 65536.0f);
    uint32_t w4 = w0 * 2654435761u + w1;
    uint32_t w5 = w4 * 2654435761u + w2;
    uint32_t w6 = w5 * 2654435761u + w3;
    uint32_t cs = w6 * 2654435761u + f32_to_u32((z2 + 8.0f) * 65536.0f);
    return (V2){cs, eb};
  }
  float ax = x1 - x0, ay = y1 - y0, az = z1 - z0;
  float da = (ax * ax + (ay * ay + az * az)) + 0.05f;
  float ia = 1.0f / sqrtf(da);
  float i3a = (ia * ia) * ia;
  float qax = ax * i3a, qay = ay * i3a, qaz = az * i3a;
  float bx = x2 - x0, by = y2 - y0, bz = z2 - z0;
  float db = (bx * bx + (by * by + bz * bz)) + 0.05f;
  float ib = 1.0f / sqrtf(db);
  float i3b = (ib * ib) * ib;
  float qbx = bx * i3b, qby = by * i3b, qbz = bz * i3b;
  float cx = x2 - x1, cy = y2 - y1, cz = z2 - z1;
  float dc = (cx * cx + (cy * cy + cz * cz)) + 0.05f;
  float ic = 1.0f / sqrtf(dc);
  float i3c = (ic * ic) * ic;
  float qcx = cx * i3c, qcy = cy * i3c, qcz = cz * i3c;
  float nvx0 = vx0 + (qax * m1 + qbx * m2) * 0.001f;
  float nvy0 = vy0 + (qay * m1 + qby * m2) * 0.001f;
  float nvz0 = vz0 + (qaz * m1 + qbz * m2) * 0.001f;
  float nvx1 = vx1 + (qcx * m2 - qax * m0) * 0.001f;
  float nvy1 = vy1 + (qcy * m2 - qay * m0) * 0.001f;
  float nvz1 = vz1 + (qcz * m2 - qaz * m0) * 0.001f;
  float nvx2 = vx2 - (qbx * m0 + qcx * m1) * 0.001f;
  float nvy2 = vy2 - (qby * m0 + qcy * m1) * 0.001f;
  float nvz2 = vz2 - (qbz * m0 + qcz * m1) * 0.001f;
  // clang's TRE skips small-struct returns; musttail restores the loop
  __attribute__((musttail)) return loop3(s - 1, x0 + nvx0 * 0.001f, y0 + nvy0 * 0.001f,
               z0 + nvz0 * 0.001f, x1 + nvx1 * 0.001f, y1 + nvy1 * 0.001f,
               z1 + nvz1 * 0.001f, x2 + nvx2 * 0.001f, y2 + nvy2 * 0.001f,
               z2 + nvz2 * 0.001f, nvx0, nvy0, nvz0, nvx1, nvy1, nvz1, nvx2,
               nvy2, nvz2, m0, m1, m2);
}

// one random system: three seeded bodies, ST steps, digest
static V2 sim(uint32_t sd, uint32_t st) {
  uint32_t a1 = prng((sd * 12 + 1) * 2654435761u);
  uint32_t a2 = prng((sd * 12 + 2) * 2654435761u);
  uint32_t a3 = prng((sd * 12 + 3) * 2654435761u);
  uint32_t a4 = prng((sd * 12 + 4) * 2654435761u);
  uint32_t b1 = prng((sd * 12 + 5) * 2654435761u);
  uint32_t b2 = prng((sd * 12 + 6) * 2654435761u);
  uint32_t b3 = prng((sd * 12 + 7) * 2654435761u);
  uint32_t b4 = prng((sd * 12 + 8) * 2654435761u);
  uint32_t c1 = prng((sd * 12 + 9) * 2654435761u);
  uint32_t c2 = prng((sd * 12 + 10) * 2654435761u);
  uint32_t c3 = prng((sd * 12 + 11) * 2654435761u);
  uint32_t c4 = prng((sd * 12 + 12) * 2654435761u);
  float x0 = (float)(a1 & 65535) / 32768.0f - 1.0f;
  float y0 = (float)(a2 & 65535) / 32768.0f - 1.0f;
  float z0 = (float)(a3 & 65535) / 32768.0f - 1.0f;
  float m0 = (float)(a4 & 65535) / 65536.0f + 0.5f;
  float x1 = (float)(b1 & 65535) / 32768.0f - 1.0f;
  float y1 = (float)(b2 & 65535) / 32768.0f - 1.0f;
  float z1 = (float)(b3 & 65535) / 32768.0f - 1.0f;
  float m1 = (float)(b4 & 65535) / 65536.0f + 0.5f;
  float x2 = (float)(c1 & 65535) / 32768.0f - 1.0f;
  float y2 = (float)(c2 & 65535) / 32768.0f - 1.0f;
  float z2 = (float)(c3 & 65535) / 32768.0f - 1.0f;
  float m2 = (float)(c4 & 65535) / 65536.0f + 0.5f;
  float vx0 = y0 * 0.1f, vy0 = 0.0f - x0 * 0.1f;
  float vx1 = y1 * 0.1f, vy1 = 0.0f - x1 * 0.1f;
  float vx2 = y2 * 0.1f, vy2 = 0.0f - x2 * 0.1f;
  return loop3(st, x0, y0, z0, x1, y1, z1, x2, y2, z2, vx0, vy0, 0.0f, vx1,
               vy1, 0.0f, vx2, vy2, 0.0f, m0, m1, m2);
}

// fork leaf: 8 systems; outcome histogram in 8 scalar counters plus a
// position-weighted digest accumulator
static Hs chunk(uint32_t j, uint32_t i, uint32_t st, uint32_t h0, uint32_t h1,
                uint32_t h2, uint32_t h3, uint32_t h4, uint32_t h5,
                uint32_t h6, uint32_t h7, uint32_t cs) {
  if (j == 0)
    return (Hs){h0, h1, h2, h3, h4, h5, h6, h7, cs};
  uint32_t p = j - 1;
  uint32_t sy = i + p;
  V2 w = sim(sy, st);
  uint32_t bb = w.eb;
  return chunk(p, i, st, h0 + (bb == 0), h1 + (bb == 1), h2 + (bb == 2),
               h3 + (bb == 3), h4 + (bb == 4), h5 + (bb == 5), h6 + (bb == 6),
               h7 + (bb == 7), cs + w.cs * (sy * 2654435761u + 1));
}

static Hs hzip(Hs a, Hs b) {
  return (Hs){a.h0 + b.h0, a.h1 + b.h1, a.h2 + b.h2, a.h3 + b.h3,
              a.h4 + b.h4, a.h5 + b.h5, a.h6 + b.h6, a.h7 + b.h7,
              a.cs + b.cs};
}

static Hs batch(uint32_t d, uint32_t i, uint32_t st) {
  if (d == 0)
    return chunk(8, i, st, 0, 0, 0, 0, 0, 0, 0, 0, 0);
  uint32_t p = d - 1;
  Hs a = batch(p, i, st);
  Hs b = batch(p, i + (8u << p), st);
  return hzip(a, b);
}

static uint32_t run_fin(Hs t) {
  uint32_t g1 = t.h0 * 2654435761u + t.h1;
  uint32_t g2 = g1 * 2654435761u + t.h2;
  uint32_t g3 = g2 * 2654435761u + t.h3;
  uint32_t g4 = g3 * 2654435761u + t.h4;
  uint32_t g5 = g4 * 2654435761u + t.h5;
  uint32_t g6 = g5 * 2654435761u + t.h6;
  uint32_t g7 = g6 * 2654435761u + t.h7;
  return g7 * 2654435761u + t.cs;
}

static uint32_t run(uint32_t d, uint32_t ts) { return run_fin(batch(d, 0, ts)); }

int main(void) {
  printf("%u\n", run(SY, ST));
  return 0;
}
