// Native C twin of main.bend: Conway soup census. Single-threaded,
// 1-to-1 with the Bend program: same bit-packed 4x4-torus step, SWAR
// popcount, two-probe classification, 64-soup chunk accumulators and census
// merge, same wrapping-u32 numerics.
#include <stdint.h>
#include <stdio.h>

typedef enum Cls {
  CLS_STILL,
  CLS_OSC,
  CLS_CHAOS,
} Cls;

typedef struct Census {
  uint32_t pop;
  uint32_t still;
  uint32_t osc;
  uint32_t mix;
} Census;

static uint32_t b2u(uint32_t b) { return b ? 1u : 0u; }

static uint32_t cell_get(uint32_t board, uint32_t r, uint32_t c) {
  return (board >> (((r & 3u) * 4u + (c & 3u)) & 31u)) & 1u;
}

static uint32_t neighbor_count(uint32_t board, uint32_t r, uint32_t c) {
  return cell_get(board, r - 1u, c - 1u) + cell_get(board, r - 1u, c) +
         cell_get(board, r - 1u, c + 1u) + cell_get(board, r, c - 1u) +
         cell_get(board, r, c + 1u) + cell_get(board, r + 1u, c - 1u) +
         cell_get(board, r + 1u, c) + cell_get(board, r + 1u, c + 1u);
}

static uint32_t next_dead(uint32_t n) { return b2u(n == 3u); }

static uint32_t next_alive(uint32_t n) {
  return b2u((n == 2u) | (n == 3u));
}

static uint32_t next_cell_go(uint32_t n, uint32_t z) {
  return z ? next_dead(n) : next_alive(n);
}

static uint32_t next_cell(uint32_t a, uint32_t n) {
  return next_cell_go(n, a == 0u);
}

static uint32_t step_cell(uint32_t board, uint32_t pos) {
  uint32_t r = pos >> 2u;
  uint32_t c = pos & 3u;
  uint32_t alive = cell_get(board, r, c);
  uint32_t neighbors = neighbor_count(board, r, c);
  return next_cell(alive, neighbors) << (pos & 31u);
}

static inline __attribute__((always_inline)) uint32_t board_step(uint32_t b) {
  return step_cell(b, 0u) | step_cell(b, 1u) | step_cell(b, 2u) |
         step_cell(b, 3u) | step_cell(b, 4u) | step_cell(b, 5u) |
         step_cell(b, 6u) | step_cell(b, 7u) | step_cell(b, 8u) |
         step_cell(b, 9u) | step_cell(b, 10u) | step_cell(b, 11u) |
         step_cell(b, 12u) | step_cell(b, 13u) | step_cell(b, 14u) |
         step_cell(b, 15u);
}

static uint32_t board_run(uint32_t n, uint32_t board) {
  if (n == 0u) {
    return board;
  }
  return board_run(n - 1u, board_step(board));
}

// 16-bit SWAR population count
static uint32_t board_popcount(uint32_t b) {
  uint32_t a = b - ((b >> 1u) & 21845u);
  uint32_t c = (a & 13107u) + ((a >> 2u) & 13107u);
  uint32_t d = (c + (c >> 4u)) & 3855u;
  return (d * 257u >> 8u) & 31u;
}

static Cls classify_p2(uint32_t t) { return t ? CLS_OSC : CLS_CHAOS; }

static Cls classify_go(uint32_t t, uint32_t n1, uint32_t b) {
  return t ? CLS_STILL : classify_p2(board_step(n1) == b);
}

static Cls classify_p1(uint32_t n1, uint32_t b) {
  return classify_go(n1 == b, n1, b);
}

// classify the settled board by two probe steps
static Cls board_classify(uint32_t b) { return classify_p1(board_step(b), b); }

// one soup: hash the soup index into a 16-bit board, run GENS steps
static uint32_t soup_sim(uint32_t ix, uint32_t g) {
  return board_run(g, (ix * 2654435761u) & 65535u);
}

// class code: Still 0, Osc 1, Chaos 2
static uint32_t cls_code(Cls c) { return (uint32_t)c; }

// leaf chunk: 64 soups folded into scalar accumulators
static Census chunk_run(uint32_t j, uint32_t i, uint32_t g, uint32_t pa,
                        uint32_t sa, uint32_t oa, uint32_t mx) {
  if (j == 0u) {
    return (Census){pa, sa, oa, mx};
  }
  uint32_t p = j - 1u;
  uint32_t bd = soup_sim(i + p, g);
  uint32_t cd = cls_code(board_classify(bd));
  return chunk_run(p, i, g, pa + board_popcount(bd), sa + b2u(cd == 0u),
                   oa + b2u(cd == 1u), (mx * 2654435761u) ^ bd);
}

static Census census_zip(Census a, Census b) {
  return (Census){a.pop + b.pop, a.still + b.still, a.osc + b.osc,
                  a.mix * 2654435761u + b.mix};
}

static Census batch_run(uint32_t d, uint32_t i, uint32_t g) {
  if (d == 0u) {
    return chunk_run(64u, i, g, 0u, 0u, 0u, 0u);
  }
  Census a = batch_run(d - 1u, i, g);
  Census b = batch_run(d - 1u, i + (64u << (d - 1u)), g);
  return census_zip(a, b);
}

// final checksum: mix the census fields
static uint32_t census_fin(Census c) {
  return ((c.pop * 2654435761u + c.still) * 2654435761u + c.osc) *
             2654435761u +
         c.mix;
}

int main(void) {
  uint32_t size = 18u;
  uint32_t gens = 32u;
  printf("%u\n", census_fin(batch_run(size, 0u, gens)));
  return 0;
}
