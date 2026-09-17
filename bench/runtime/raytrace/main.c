// Single-threaded C twin of main.bend. Same
// scene of 9 spheres + one point light at (-3,8,1), same 2x2
// supersampled pixels (four primary rays at (0.25,0.75) offsets),
// nearest-hit + Lambertian shadow shading + mirror bounce on a
// countdown depth (4). trace is in the bench's accumulator form: per
// bounce acc' = acc + ((w*lum)*(1-kr)), w' = w*kr, final level adds
// acc + (w*lum); nearest folds spheres 8 down to 0 with strict <. The
// Bend row-fork reduction is a plain row loop here (u32 wrapping sum,
// associative). All f32, one operation per statement order preserved.
// Build: cc -O3 main.c -lm.
// Expected at ROWS=12, WIDTH=6000: 1924309504 with -ffp-contract=off
// (Bend's uncontracted f32 bits; plain -O3 fuses a*b+c into fma and
// prints 1924309520); ROWS=6, WIDTH=80: 402971.

#include <stdint.h>
#include <stdio.h>
#include <math.h>

#define ROWS 12u
#define WIDTH 6000u
#define NS 9u
#define DEPTH 4u

typedef struct { float x, y, z, r, kr; } Sph;

static const Sph SP[NS] = {
  {  0.0f, -10001.0f, 5.0f, 10000.0f, 0.3f },
  {  0.0f,      0.0f, 5.0f,     1.0f, 0.7f },
  {  2.0f,      0.5f, 6.0f,     1.0f, 0.4f },
  { -2.0f,      0.5f, 6.0f,     1.0f, 0.4f },
  {  1.0f,     -0.6f, 3.5f,     0.4f, 0.9f },
  { -1.0f,     -0.6f, 3.5f,     0.4f, 0.9f },
  {  0.0f,      1.6f, 7.0f,     1.2f, 0.1f },
  {  3.5f,      0.2f, 8.0f,     1.0f, 0.6f },
  { -3.5f,      0.2f, 8.0f,     1.0f, 0.6f },
};

typedef struct { float t; uint32_t i; } Hit;

// ray-sphere: t of the near root, or 1e9 for a miss (disc < 0 or t < eps)
static float sphere_isect(uint32_t i, float ox, float oy, float oz,
                          float dx, float dy, float dz) {
  float px = ox - SP[i].x;
  float py = oy - SP[i].y;
  float pz = oz - SP[i].z;
  float r  = SP[i].r;
  float b  = (px*dx + py*dy) + pz*dz;
  float c  = ((px*px + py*py) + pz*pz) - r*r;
  float disc = b*b - c;
  if (disc < 0.0f) return 1e9f;
  float t = (0.0f - b) - sqrtf(disc);
  if (t < 0.001f) return 1e9f;
  return t;
}

static Hit scene_nearest(float ox, float oy, float oz,
                         float dx, float dy, float dz, float bt, uint32_t bi) {
  for (uint32_t i = NS; i > 0; i--) {
    float t = sphere_isect(i - 1, ox, oy, oz, dx, dy, dz);
    if (t < bt) { bt = t; bi = i - 1; }
  }
  return (Hit){ bt, bi };
}

// t-only nearest for the shadow probe: same fold, bare min distance
static float scene_nearest_t(float ox, float oy, float oz,
                             float dx, float dy, float dz, float bt) {
  for (uint32_t i = NS; i > 0; i--) {
    float t = sphere_isect(i - 1, ox, oy, oz, dx, dy, dz);
    if (t < bt) bt = t;
  }
  return bt;
}

static float float_fmax0(float x) {
  if (x < 0.0f) return 0.0f;
  return x;
}

// diffuse term, zeroed when the shadow ray hits something before the light
static float hit_shade(float st, float ll, float df) {
  if (st < ll) return 0.0f;
  return df;
}

static float float_clamp01(float x) {
  if (x < 0.0f) return 0.0f;
  if (1.0f < x) return 1.0f;
  return x;
}

static float ray_trace(uint32_t dep, float ox, float oy, float oz,
                       float dx, float dy, float dz, float acc, float w) {
  Hit h = scene_nearest(ox, oy, oz, dx, dy, dz, 1e9f, NS);
  if (h.i == NS) return acc;
  float t  = h.t;
  Sph  s  = SP[h.i];
  float hx = ox + t*dx;
  float hy = oy + t*dy;
  float hz = oz + t*dz;
  float nx = (hx - s.x) / s.r;
  float ny = (hy - s.y) / s.r;
  float nz = (hz - s.z) / s.r;
  float lvx = -3.0f - hx;
  float lvy =  8.0f - hy;
  float lvz =  1.0f - hz;
  float ll = sqrtf((lvx*lvx + lvy*lvy) + lvz*lvz);
  float lx = lvx / ll;
  float ly = lvy / ll;
  float lz = lvz / ll;
  float df = float_fmax0((nx*lx + ny*ly) + nz*lz);
  float sox = hx + 0.001f*nx;
  float soy = hy + 0.001f*ny;
  float soz = hz + 0.001f*nz;
  float st = scene_nearest_t(sox, soy, soz, lx, ly, lz, 1e9f);
  float lum = 0.1f + 0.85f * hit_shade(st, ll, df);
  if (dep == 0) return acc + w*lum;
  float k2 = 2.0f * ((dx*nx + dy*ny) + dz*nz);
  return ray_trace(dep - 1, sox, soy, soz,
                   dx - k2*nx, dy - k2*ny, dz - k2*nz,
                   acc + (w*lum) * (1.0f - s.kr), w * s.kr);
}

static float ray_sub(float fx, float fy) {
  float dl = sqrtf((fx*fx + fy*fy) + 1.0f);
  return ray_trace(DEPTH, 0.0f, 0.0f, 0.0f, fx/dl, fy/dl, 1.0f/dl, 0.0f, 1.0f);
}

// 2x2 supersampled pixel
static uint32_t pixel_render(uint32_t x, uint32_t y, float hw, float hh) {
  float xf = (float)x;
  float yf = (float)y;
  float l1 = ray_sub(((xf + 0.25f) - hw) / hw, (hh - (yf + 0.25f)) / hw);
  float l2 = ray_sub(((xf + 0.75f) - hw) / hw, (hh - (yf + 0.25f)) / hw);
  float l3 = ray_sub(((xf + 0.25f) - hw) / hw, (hh - (yf + 0.75f)) / hw);
  float l4 = ray_sub(((xf + 0.75f) - hw) / hw, (hh - (yf + 0.75f)) / hw);
  return (uint32_t)(255.0f * float_clamp01(((l1 + l2) + (l3 + l4)) * 0.25f));
}

int main(void) {
  uint32_t w  = WIDTH;
  uint32_t h  = 1u << ROWS;
  float    hw = (float)(w / 2);
  float    hh = (float)(h / 2);
  uint32_t acc = 0;
  // the Bend fork tree permutes row/column indices by odd multipliers
  // (bijections: same pixel set, same u32 sum); mirrored here
  for (uint32_t yj = 0; yj < h; yj++) {
    uint32_t y = (yj * 1588635697u) & (h - 1u);
    for (uint32_t xj = 0; xj < 16384u; xj++) {
      uint32_t x = (xj * 2654435761u) & 16383u;
      if (x < w)
        acc += pixel_render(x, y, hw, hh);
    }
  }
  printf("%u\n", acc);
  return 0;
}
