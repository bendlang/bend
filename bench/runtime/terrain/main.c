// Native C twin of main.bend: procedural terrain tile pipeline.
// Single-threaded, 1-to-1 with the Bend program: same value-noise fill,
// in-place Gauss-Seidel relaxation sweeps with pass-salted roughening,
// 64-bin histogram and position-weighted folds, wrapping-u32 numerics.
#include <stdint.h>
#include <stdio.h>
#include <string.h>

static uint32_t word_prng(uint32_t x) {
  uint32_t b = x ^ (x << 13u);
  uint32_t d = b ^ (b >> 17u);
  return d ^ (d << 5u);
}

// lattice corner hash -> 0..255
static uint32_t lattice_hash(uint32_t gx, uint32_t gz) {
  return word_prng((gx * 2654435761u) ^ (gz * 340573321u)) & 255u;
}

// value noise at 8.8 fixed-point (x, z): bilinear lerp of 4 corner hashes
static uint32_t terrain_ground(uint32_t x, uint32_t z) {
  uint32_t gx = (x >> 8u) & 63u;
  uint32_t gz = (z >> 8u) & 63u;
  uint32_t fx = x & 255u;
  uint32_t fz = z & 255u;
  uint32_t gx1 = (gx + 1u) & 63u;
  uint32_t gz1 = (gz + 1u) & 63u;
  uint32_t h00 = lattice_hash(gx, gz);
  uint32_t h10 = lattice_hash(gx1, gz);
  uint32_t h01 = lattice_hash(gx, gz1);
  uint32_t h11 = lattice_hash(gx1, gz1);
  uint32_t t0 = (h00 * (256u - fx) + h10 * fx) >> 8u;
  uint32_t t1 = (h01 * (256u - fx) + h11 * fx) >> 8u;
  return (t0 * (256u - fz) + t1 * fz) >> 8u;
}

// noise-fill one tile: one write per cell
static void tile_fill(uint32_t ox, uint32_t oz, uint32_t *h) {
  for (uint32_t i = 0u; i < 4096u; ++i) {
    h[i] = terrain_ground((ox + (i & 63u)) << 6u, (oz + (i >> 6u)) << 6u);
  }
}

// one relaxation cell: 5 reads + 1 write, clamped neighbours,
// pass-salted 1-bit roughening
static void erode_cell(uint32_t i, uint32_t p, uint32_t *h) {
  uint32_t xc = i & 63u;
  uint32_t zc = i >> 6u;
  uint32_t hc = h[i];
  uint32_t hl = h[i - (xc > 0u ? 1u : 0u)];
  uint32_t hr = h[i + (xc < 63u ? 1u : 0u)];
  uint32_t hu = h[i - ((zc > 0u ? 1u : 0u) << 6u)];
  uint32_t hd = h[i + ((zc < 63u ? 1u : 0u) << 6u)];
  uint32_t rough = word_prng(i ^ (p * 2654435761u)) & 1u;
  h[i] = ((hc * 4u + hl + hr + hu + hd) >> 3u) + rough;
}

// four cells per erode turn, as in the Bend twin's erode.go quad
static void erode_go(uint32_t i, uint32_t p, uint32_t *h) {
  erode_cell(i, p, h);
  erode_cell(i + 1u, p, h);
  erode_cell(i + 2u, p, h);
  erode_cell(i + 3u, p, h);
}

// one Gauss-Seidel sweep over the tile, ascending scan order
static void tile_erode(uint32_t p, uint32_t *h) {
  for (uint32_t i = 0u; i < 4096u; i += 4u) {
    erode_go(i, p, h);
  }
}

static void tile_smooth(uint32_t p, uint32_t *h) {
  while (p != 0u) {
    tile_erode(p, h);
    --p;
  }
}

// histogram fold: mix every bucket count, position-weighted
static uint32_t hist_fold(const uint32_t *g, uint32_t acc) {
  for (uint32_t i = 0u; i < 64u; ++i) {
    acc = (acc * 2654435761u) ^ (g[i] * (i + 3u));
  }
  return acc;
}

// per cell: read the height, bump its histogram bucket, mix the height
static uint32_t tile_hist(const uint32_t *h, uint32_t *g, uint32_t acc) {
  for (uint32_t i = 0u; i < 4096u; ++i) {
    uint32_t v = h[i];
    uint32_t b = (v >> 2u) & 63u;
    g[b] += 1u;
    acc = acc * 2654435761u + v * (i + 1u);
  }
  return hist_fold(g, acc);
}

// one tile: fill, EPASS relaxation sweeps, histogram + fold
static uint32_t tile_run(uint32_t t, uint32_t e) {
  uint32_t h[4096];
  uint32_t g[64];
  uint32_t ox = (t & 255u) << 6u;
  uint32_t oz = (t >> 8u) << 6u;
  tile_fill(ox, oz, h);
  tile_smooth(e, h);
  memset(g, 0, sizeof(g));
  return tile_hist(h, g, t + 1u);
}

static uint32_t batch_run(uint32_t d, uint32_t t, uint32_t e) {
  if (d == 0u) {
    return tile_run(t, e);
  }
  uint32_t a = batch_run(d - 1u, t, e);
  uint32_t b = batch_run(d - 1u, t + (1u << (d - 1u)), e);
  return a + b;
}

int main(void) {
  uint32_t size = 16u;
  uint32_t epass = 5u;
  printf("%u\n", batch_run(size, 0u, epass));
  return 0;
}
