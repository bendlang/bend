// Single-threaded C twin of main.bend. Same algorithm, same shape:
// 4-row prefix decode + bitmask legality, then the classic bitmask
// backtracker over the remaining rows threading per-branch
// Stats{sols, nodes}: peel b = cand & -cand, descend on the child
// candidate word, loop on the sibling set. The Bend fork tree's
// smerge reduction is a plain sum over the prefix index space.
// Checksum = (sols * 2654435761) ^ nodes.
// Expected at DEPTH=17, SIZE=17, LIMIT=11730: 2063750025.

#include <stdint.h>
#include <stdio.h>

#define DEPTH 17u
#define SIZE 17u
#define LIMIT 11730u

typedef struct {
  uint32_t sols, nodes;
} Stats;

static Stats solve(uint32_t cand, uint32_t cols, uint32_t ld, uint32_t rd,
                   uint32_t full, uint32_t sols, uint32_t nodes) {
  while (cand != 0u) {
    uint32_t bit = cand & (0u - cand);
    uint32_t nc = cols | bit;
    if (nc == full) {
      sols += 1u;
      nodes += 1u;
    } else {
      uint32_t nl = (ld | bit) << 1;
      uint32_t nr = (rd | bit) >> 1;
      Stats w = solve(full & ~(nc | nl | nr), nc, nl, nr, full, sols,
                      nodes + 1u);
      sols = w.sols;
      nodes = w.nodes;
    }
    cand -= bit;
  }
  return (Stats){sols, nodes};
}

// one 4-row prefix: permute the fork index, decode the column quad,
// filter illegal placements, solve the remaining rows
static Stats pfx(uint32_t j, uint32_t nn, uint32_t full, uint32_t bound) {
  uint32_t i = (j * 2654435761u) & ((1u << DEPTH) - 1u);
  if (!(i < bound))
    return (Stats){0u, 0u};
  uint32_t nn2 = nn * nn;
  uint32_t b0 = 1u << (i / (nn2 * nn));
  uint32_t b1 = 1u << ((i / nn2) % nn);
  if ((b1 & (b0 | (b0 << 1) | (b0 >> 1))) != 0u)
    return (Stats){0u, 0u};
  uint32_t b2 = 1u << ((i / nn) % nn);
  uint32_t c2 = b0 | b1;
  uint32_t l2 = ((b0 << 1) | b1) << 1;
  uint32_t r2 = ((b0 >> 1) | b1) >> 1;
  if ((b2 & (c2 | l2 | r2)) != 0u)
    return (Stats){0u, 0u};
  uint32_t b3 = 1u << (i % nn);
  uint32_t c3 = c2 | b2;
  uint32_t l3 = (l2 | b2) << 1;
  uint32_t r3 = (r2 | b2) >> 1;
  if ((b3 & (c3 | l3 | r3)) != 0u)
    return (Stats){0u, 0u};
  uint32_t c4 = c3 | b3;
  uint32_t l4 = (l3 | b3) << 1;
  uint32_t r4 = (r3 | b3) >> 1;
  return solve(full & ~(c4 | l4 | r4), c4, l4, r4, full, 0u, 0u);
}

static uint32_t run(uint32_t nn, uint32_t lim) {
  uint32_t full = (1u << nn) - 1u;
  uint32_t nnnn = nn * nn * nn * nn;
  uint32_t bound = lim < nnnn ? lim : nnnn;
  uint32_t sols = 0u, nodes = 0u;
  for (uint32_t i = 0u; i < (1u << DEPTH); ++i) {
    Stats s = pfx(i, nn, full, bound);
    sols += s.sols;
    nodes += s.nodes;
  }
  return (sols * 2654435761u) ^ nodes;
}

int main(void) {
  printf("%u\n", run(SIZE, LIMIT));
  return 0;
}
