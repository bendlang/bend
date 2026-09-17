// Native C twin of main.bend: Levenshtein edit distance by dynamic
// programming, single-threaded, 1-to-1 with the Bend program: the
// same xorshift symbol streams (sequences are byte strings), the same
// two rolling uint32 rows swapping roles after every row, the same
// min chain and cost test per cell, and the same checksum fold over
// the pair index space.
#include <stdint.h>
#include <stdio.h>

#ifndef DEPTH
#define DEPTH 15
#endif
#define N 256u

static uint32_t word_prng(uint32_t x) {
  uint32_t b = x ^ (x << 13u);
  uint32_t d = b ^ (b >> 17u);
  return d ^ (d << 5u);
}

static uint32_t word_min(uint32_t x, uint32_t y) { return x < y ? x : y; }

// draw one sequence: step the stream, keep its low two bits
static void seq_gen(uint32_t s, uint8_t *x) {
  for (uint32_t k = 0u; k < N; ++k) {
    s = word_prng(s);
    x[k] = (uint8_t)(s & 3u);
  }
}

// the DP: prev[j] = j at the start; row i reads a[i] once, writes
// cur[0] = i + 1, fills cur[1..N], then the rows swap roles
static uint32_t edit_dist(const uint8_t *a, const uint8_t *b) {
  uint32_t rows[2][N + 1u];
  uint32_t *prev = rows[0];
  uint32_t *cur = rows[1];
  for (uint32_t k = 0u; k <= N; ++k) {
    prev[k] = k;
  }
  for (uint32_t i = 0u; i < N; ++i) {
    uint32_t ai = a[i];
    cur[0] = i + 1u;
    for (uint32_t j = 0u; j < N; ++j) {
      uint32_t cost = ai != b[j] ? 1u : 0u;
      cur[j + 1u] =
          word_min(word_min(prev[j + 1u] + 1u, cur[j] + 1u), prev[j] + cost);
    }
    uint32_t *t = prev;
    prev = cur;
    cur = t;
  }
  return prev[N];
}

// one pair: seed from the hashed pair index, draw a and b, run the
// DP, mix the distance with the index
static uint32_t pair_run(uint32_t p) {
  uint8_t a[N];
  uint8_t b[N];
  uint32_t s = (p + 1u) * 2654435761u;
  seq_gen(s, a);
  seq_gen(s * 340573321u, b);
  return (edit_dist(a, b) * 2654435761u) ^ (p + 1u);
}

static uint32_t batch_run(uint32_t d, uint32_t p) {
  if (d == 0u) {
    return pair_run(p);
  }
  uint32_t x = batch_run(d - 1u, p);
  uint32_t y = batch_run(d - 1u, p + (1u << (d - 1u)));
  return x + y;
}

int main(void) {
  printf("%u\n", batch_run(DEPTH, 0u));
  return 0;
}
