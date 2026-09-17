// Native C twin of main.bend: breadth-first search over 2^DEPTH
// independent 32x32 grid mazes, single-threaded, 1-to-1 with the Bend
// program: same seed and wall hash, a flat uint32 grid (1 open, 0
// wall), a flat uint32 queue with head and tail, a flat uint32 distance
// map seeded unseen, the textbook pop loop with four bounds-checked
// neighbour looks, and the same position-weighted fold sealed by the
// reached count; leaf checksums sum up the batch recursion.
#include <stdint.h>
#include <stdio.h>

#ifndef DEPTH
#define DEPTH 19
#endif

#define CELLS 1024u
#define UNSEEN 0xFFFFFFFFu

typedef struct Bfs {
  uint32_t g[CELLS], q[CELLS], d[CELLS];
  uint32_t head, tail;
} Bfs;

static uint32_t word_prng(uint32_t x) {
  uint32_t b = x ^ (x << 13u);
  uint32_t d = b ^ (b >> 17u);
  return d ^ (d << 5u);
}

// 1 when cell c of the maze seeded s is open: the start always, any
// other cell when its hash mod 100 is 30 or more (30% walls)
static uint32_t cell_open(uint32_t s, uint32_t c) {
  uint32_t h = word_prng(s ^ ((c + 1u) * 340573321u));
  return c == 0u || h % 100u >= 30u;
}

// one neighbour n at distance v: skip it out of bounds, a wall or
// seen; else stamp its distance and push it
static void bfs_look(Bfs *b, uint32_t n, uint32_t v, int inb) {
  if (inb && b->g[n] != 0u && b->d[n] == UNSEEN) {
    b->d[n] = v;
    b->q[b->tail] = n;
    b->tail += 1u;
  }
}

// one pop: the head cell and its distance, then its four neighbours
static void bfs_pop(Bfs *b) {
  uint32_t c = b->q[b->head];
  uint32_t v = b->d[c] + 1u;
  uint32_t x = c & 31u;
  uint32_t y = c >> 5u;
  b->head += 1u;
  bfs_look(b, c - 1u, v, x > 0u);
  bfs_look(b, c + 1u, v, x < 31u);
  bfs_look(b, c - 32u, v, y > 0u);
  bfs_look(b, c + 32u, v, y < 31u);
}

// the leaf checksum: a reached cell mixes its distance position-
// weighted and counts one; the count seals the mix
static uint32_t bfs_fold(const Bfs *b) {
  uint32_t acc = 0u;
  uint32_t cnt = 0u;
  for (uint32_t c = 0u; c < CELLS; ++c) {
    uint32_t v = b->d[c];
    uint32_t hit = v != UNSEEN;
    acc = (acc * 2654435761u) ^ (hit ? v * (c + 1u) : 0u);
    cnt += hit;
  }
  return acc ^ (cnt * 2246822519u);
}

// one maze: fill the grid, seed the search with cell 0 at distance 0,
// search, fold
static uint32_t maze_run(uint32_t m) {
  Bfs b;
  uint32_t s = (m + 1u) * 2654435761u;
  for (uint32_t c = 0u; c < CELLS; ++c) {
    b.g[c] = cell_open(s, c);
    b.d[c] = UNSEEN;
    b.q[c] = 0u;
  }
  b.d[0] = 0u;
  b.head = 0u;
  b.tail = 1u;
  while (b.head < b.tail) {
    bfs_pop(&b);
  }
  return bfs_fold(&b);
}

static uint32_t batch_run(uint32_t k, uint32_t i) {
  if (k == 0u) {
    return maze_run(i);
  }
  uint32_t a = batch_run(k - 1u, i);
  uint32_t b = batch_run(k - 1u, i + (1u << (k - 1u)));
  return a + b;
}

int main(void) {
  printf("%u\n", batch_run(DEPTH, 0u));
  return 0;
}
