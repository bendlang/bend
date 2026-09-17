// Native C twin of main.bend: a hash table with separate chaining
// over 2^S independent tables, single-threaded, 1-to-1 with the Bend
// program: same xorshift key of the seed and draw index masked to 20
// bits, same low-12-bit bucket, same walk (it stops at the found
// key; Bend's stops one node later), same head insert, same hit
// count, same position-weighted fold over the chain lengths, same
// sum over the table tree, wrapping-u32 numerics. Where Bend's
// buckets hold boxed Chain values that Array.get shares and
// Array.set swaps, a table here is one array of bucket heads over an
// index-linked node pool (a key column and a next column, KEYS nodes
// at most), walked and pushed in place and reset per table.
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#ifndef TABLES
#define TABLES 11
#endif
#ifndef KEYS
#define KEYS 16384
#endif

#define NIL 0xFFFFFFFFu

typedef struct {
  uint32_t head[4096];
  uint32_t key[KEYS];
  uint32_t next[KEYS];
  uint32_t used;
} Table;

static Table tab;

static uint32_t word_prng(uint32_t x) {
  uint32_t b = x ^ (x << 13u);
  uint32_t d = b ^ (b >> 17u);
  return d ^ (d << 5u);
}

// a key: the hash of a seed and a draw index, masked to 20 bits
static uint32_t draw_key(uint32_t s, uint32_t j) {
  uint32_t h = word_prng(((j + 1u) * 2654435761u) ^ (s * 340573321u));
  return h & 1048575u;
}

// the chain walk: 1 when the key is in bucket b, stopping at it
static uint32_t table_has(const Table *t, uint32_t b, uint32_t k) {
  for (uint32_t n = t->head[b]; n != NIL; n = t->next[n]) {
    if (t->key[n] == k) {
      return 1u;
    }
  }
  return 0u;
}

// one insert: a present key leaves the bucket untouched, an absent
// one takes a fresh node at the chain's head
static void table_ins(Table *t, uint32_t k) {
  uint32_t b = k & 4095u;
  if (!table_has(t, b, k)) {
    uint32_t n = t->used++;
    t->key[n] = k;
    t->next[n] = t->head[b];
    t->head[b] = n;
  }
}

// a chain's length
static uint32_t table_len(const Table *t, uint32_t b) {
  uint32_t l = 0u;
  for (uint32_t n = t->head[b]; n != NIL; n = t->next[n]) {
    l++;
  }
  return l;
}

// one table: D inserts from the table seed, D lookups from the
// second seed, then the bucket sweep: lengths summed (the distinct
// count) and mixed position-weighted, sealed with the hit count
static uint32_t table_run(uint32_t ti, uint32_t d) {
  Table *t = &tab;
  memset(t->head, 0xFF, sizeof(t->head));
  t->used = 0u;
  uint32_t s = (ti + 1u) * 2654435761u;
  for (uint32_t j = 0u; j < d; ++j) {
    table_ins(t, draw_key(s, j));
  }
  uint32_t s2 = word_prng(s);
  uint32_t hits = 0u;
  for (uint32_t j = 0u; j < d; ++j) {
    uint32_t k = draw_key(s2, j);
    hits += table_has(t, k & 4095u, k);
  }
  uint32_t cnt = 0u;
  uint32_t acc = 0u;
  for (uint32_t i = 0u; i < 4096u; ++i) {
    uint32_t l = table_len(t, i);
    cnt += l;
    acc = (acc * 2654435761u) ^ (l * (i + 3u));
  }
  return (acc ^ (hits * 2654435761u)) + cnt * 340573321u;
}

// batch tree over the table index space: table checksums sum up
static uint32_t batch_run(uint32_t p, uint32_t t, uint32_t d) {
  if (p == 0u) {
    return table_run(t, d);
  }
  uint32_t a = batch_run(p - 1u, t, d);
  uint32_t b = batch_run(p - 1u, t + (1u << (p - 1u)), d);
  return a + b;
}

int main(void) {
  printf("%u\n", batch_run(TABLES, 0u, KEYS));
  return 0;
}
