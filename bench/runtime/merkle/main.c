// Native C twin of main.bend: same Speck32/64 leaf stream, Merkle
// tree build (arena Mt nodes), audit re-fold, scalar-prover proof
// extraction and proof verification, single-threaded.
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#ifndef SIZE
#define SIZE 22
#endif
#ifndef BLOCKS
#define BLOCKS 30
#endif
#ifndef PROBE
#define PROBE 1337
#endif

static uint32_t round_key(uint32_t index) {
  static const uint16_t keys[22] = {
      256,   5394,  24957, 5208,  26905, 30690, 3209,  52443,
      61418, 20019, 30452, 22902, 61067, 56068, 17943, 62334,
      34740, 36554, 60827, 14930, 33321, 60772,
  };
  return keys[index < 21u ? index : 21u];
}

// 22 Speck rounds over the 16-bit halves x, y
static uint32_t speck_run(uint32_t rounds, uint32_t index, uint32_t x,
                          uint32_t y) {
#pragma clang loop unroll(full)
  while (rounds != 0u) {
    uint32_t next_x =
        (((((x >> 7) | (x << 9)) & 65535u) + y) & 65535u) ^ round_key(index);
    next_x &= 65535u;
    y = ((((y << 2) | (y >> 14)) & 65535u) ^ next_x) & 65535u;
    x = next_x;
    ++index;
    --rounds;
  }
  return x | (y << 16);
}

// one leaf: encrypt `count` counter blocks, chain the ciphertexts
static uint32_t block_chain(uint32_t count, uint32_t block, uint32_t acc) {
#pragma clang loop unroll_count(6)
  while (count != 0u) {
    uint32_t ciphertext =
        speck_run(22u, 0u, block & 65535u, (block >> 16) & 65535u);
    acc = acc * 2654435761u + ciphertext;
    ++block;
    --count;
  }
  return acc;
}
static uint32_t leaf_hash(uint32_t b) {
  return block_chain(BLOCKS, b * (uint32_t)BLOCKS, b + 1u);
}

// Merkle join: ARX mix of the two child hashes
static uint32_t hash_join(uint32_t left, uint32_t right) {
  uint32_t h = left * 2654435761u ^ right;
  uint32_t h2 = (h + 2246822519u) * 2246822519u ^ (h >> 13);
  return h2 ^ (h2 >> 16);
}

// the scalar prover: recompute a subtree hash without materializing it
static uint32_t hash_tree(uint32_t depth, uint32_t block) {
  if (depth == 0u)
    return leaf_hash(block);
  uint32_t left = hash_tree(depth - 1u, block);
  uint32_t right = hash_tree(depth - 1u, block + (1u << (depth - 1u)));
  return hash_join(left, right);
}

typedef enum MtTag { MT_LEAF, MT_NODE } MtTag;
typedef struct Mt {
  uint32_t tag;
  uint32_t h, l, r;
} Mt;
typedef struct MtArena {
  Mt *items;
  size_t length, capacity;
} MtArena;

static uint32_t mt_arena_push(MtArena *arena, Mt value) {
  if (arena->length == arena->capacity) {
    size_t n = arena->capacity ? arena->capacity * 2 : (2u << SIZE) - 1u;
    Mt *p = realloc(arena->items, n * sizeof(*p));
    if (!p) {
      fputs("Mt arena exhausted\n", stderr);
      exit(2);
    }
    arena->items = p;
    arena->capacity = n;
  }
  uint32_t i = (uint32_t)arena->length++;
  arena->items[i] = value;
  return i;
}
static uint32_t mt_leaf(MtArena *a, uint32_t h) {
  return mt_arena_push(a, (Mt){MT_LEAF, h, 0, 0});
}
// join two subtrees into a hashed node (peek the child hashes)
static uint32_t mt_join(MtArena *a, uint32_t l, uint32_t r) {
  uint32_t hl = a->items[l].h, hr = a->items[r].h;
  return mt_arena_push(a, (Mt){MT_NODE, hash_join(hl, hr), l, r});
}
// build the Merkle tree over blocks b .. b + 2^d - 1
static uint32_t mt_build(MtArena *a, uint32_t d, uint32_t b) {
  if (d == 0u)
    return mt_leaf(a, leaf_hash(b));
  uint32_t l = mt_build(a, d - 1u, b);
  uint32_t r = mt_build(a, d - 1u, b + (1u << (d - 1u)));
  return mt_join(a, l, r);
}
// audit: re-fold the tree; any stored-hash mismatch perturbs the result
static uint32_t mt_audit(const MtArena *a, uint32_t t) {
  Mt n = a->items[t];
  if (n.tag == MT_LEAF)
    return n.h;
  uint32_t x = mt_audit(a, n.l);
  uint32_t y = mt_audit(a, n.r);
  uint32_t m = hash_join(x, y);
  return m + (m ^ n.h);
}

typedef struct Path {
  uint32_t nil; // 1 = Pn
  uint32_t side, sib, rest;
} Path;
typedef struct PathArena {
  Path items[64];
  size_t length;
} PathArena;
static uint32_t path_push(PathArena *a, Path value) {
  a->items[a->length] = value;
  return (uint32_t)a->length++;
}
// Merkle proof for leaf k: per level, the side bit and the sibling hash
static uint32_t path_gen(PathArena *a, uint32_t d, uint32_t k, uint32_t b) {
  if (d == 0u)
    return path_push(a, (Path){1, 0, 0, 0});
  uint32_t bit = (k >> (d - 1u)) & 1u;
  uint32_t half = 1u << (d - 1u);
  uint32_t sib = hash_tree(d - 1u, bit == 0u ? b + half : b);
  uint32_t rest = path_gen(a, d - 1u, k, bit == 0u ? b : b + half);
  return path_push(a, (Path){0, bit, sib, rest});
}
// fold the proof back up from the leaf hash to a root hash
static uint32_t path_verify(const PathArena *a, uint32_t p, uint32_t lh) {
  Path n = a->items[p];
  if (n.nil)
    return lh;
  uint32_t hh = path_verify(a, n.rest, lh);
  return n.side == 0u ? hash_join(hh, n.sib) : hash_join(n.sib, hh);
}

int main(void) {
  MtArena arena = {0};
  PathArena paths = {0};
  uint32_t t = mt_build(&arena, SIZE, 0);
  uint32_t root = mt_audit(&arena, t);
  uint32_t prf = path_gen(&paths, SIZE, PROBE, 0);
  printf("%u\n", hash_join(root, path_verify(&paths, prf, leaf_hash(PROBE))));
  free(arena.items);
}
