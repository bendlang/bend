// Native C twin of main.bend: same trie sort (gen -> to_map/merge
// -> to_arr) and Chk verification scan, single-threaded. Nullary ctors
// (Emp, Free, Busy) and Single (24-bit payload) are immediate tagged
// words; only Concat and Mnode allocate, as 8-byte {l,r} pairs in index
// arenas with freelists (consuming a node in a match frees it,
// mirroring the linear semantics), so peak memory tracks the live
// input tree + trie. The final traversals (to_arr over the trie, chk
// over the sorted array) skip per-node frees: those arenas have no
// readers left.
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#ifndef DEPTH
#define DEPTH 22
#endif

#define ARENA_NIL 0xFFFFFFFFu

// Arr refs: 0 = Emp, bit 31 set = Single (payload in low 24 bits),
// otherwise Concat arena index (>= 1).
#define ARR_EMP 0u
#define ARR_SINGLE_BIT 0x80000000u
// Trie refs: 0 = Free, 1 = Busy, otherwise Mnode arena index (>= 2).
#define MAP_FREE 0u
#define MAP_BUSY 1u

typedef struct Pair {
  uint32_t l, r;
} Pair;
typedef struct Arena {
  Pair *items;
  uint32_t length, capacity;
  uint32_t free_head; // freelist threaded through .l
} Arena;

static Arena arr_arena = {0, 1, 0, ARENA_NIL};
static Arena map_arena = {0, 2, 0, ARENA_NIL};

static uint32_t arena_push(Arena *arena, uint32_t l, uint32_t r) {
  uint32_t i = arena->free_head;
  if (i != ARENA_NIL) {
    arena->free_head = arena->items[i].l;
  } else {
    if (arena->length >= arena->capacity) {
      uint32_t n = arena->capacity ? arena->capacity * 2 : (1u << 20);
      Pair *p = realloc(arena->items, (size_t)n * sizeof(*p));
      if (!p) {
        fputs("arena exhausted\n", stderr);
        exit(2);
      }
      arena->items = p;
      arena->capacity = n;
    }
    i = arena->length++;
  }
  arena->items[i].l = l;
  arena->items[i].r = r;
  return i;
}
static void arena_drop(Arena *arena, uint32_t i) {
  arena->items[i].l = arena->free_head;
  arena->free_head = i;
}
static uint32_t arr_concat(uint32_t l, uint32_t r) {
  return arena_push(&arr_arena, l, r);
}
static void arr_drop(uint32_t i) { arena_drop(&arr_arena, i); }
static uint32_t map_node(uint32_t l, uint32_t r) {
  return arena_push(&map_arena, l, r);
}
static void map_drop(uint32_t i) { arena_drop(&map_arena, i); }
// deep drop of a discarded subtree (the Mnode-vs-Busy merge arms)
static void map_drop_deep(uint32_t i) {
  if (i < 2)
    return;
  Pair x = map_arena.items[i];
  map_drop(i);
  map_drop_deep(x.l);
  map_drop_deep(x.r);
}

static uint32_t b2u(uint32_t b) { return b ? 1u : 0u; }
static uint32_t prng(uint32_t x) {
  uint32_t b = x ^ (x << 13);
  uint32_t d = b ^ (b >> 17);
  return d ^ (d << 5);
}
static uint32_t key(uint32_t i) {
  return prng((i + 1u) * 2654435761u) & 16777215u;
}

static uint32_t merge(uint32_t a, uint32_t b) {
  if (a == MAP_FREE)
    return b;
  if (a == MAP_BUSY) {
    map_drop_deep(b);
    return MAP_BUSY;
  }
  if (b == MAP_FREE)
    return a;
  if (b == MAP_BUSY) {
    map_drop_deep(a);
    return MAP_BUSY;
  }
  Pair p = map_arena.items[a], q = map_arena.items[b];
  map_drop(b);
  uint32_t l = merge(p.l, q.l);
  uint32_t r = merge(p.r, q.r);
  map_arena.items[a] = (Pair){l, r}; // reuse the consumed slot for the result
  return a;
}
static uint32_t gen(uint32_t n, uint32_t x) {
  if (!n)
    return ARR_SINGLE_BIT | key(x);
  uint32_t l = gen(n - 1, x * 2);
  uint32_t r = gen(n - 1, x * 2 + 1);
  return arr_concat(l, r);
}
static uint32_t swap_bits_go(uint32_t x0, uint32_t x1, uint32_t z) {
  return z ? map_node(x0, x1) : map_node(x1, x0);
}
static uint32_t swap_bits(uint32_t n, uint32_t x0, uint32_t x1) {
  return swap_bits_go(x0, x1, n == 0);
}
static uint32_t radix(uint32_t i, uint32_t n, uint32_t k, uint32_t r) {
  if (!i)
    return r;
  return radix(i - 1, n, k * 2, swap_bits(n & k, r, MAP_FREE));
}
static uint32_t to_map(uint32_t a) {
  if (a == ARR_EMP)
    return MAP_FREE;
  if (a & ARR_SINGLE_BIT)
    return radix(24, a & 16777215u, 1, MAP_BUSY);
  Pair x = arr_arena.items[a];
  arr_drop(a);
  uint32_t l = to_map(x.l);
  uint32_t r = to_map(x.r);
  return merge(l, r);
}
static uint32_t to_arr(uint32_t m, uint32_t k) {
  if (m == MAP_FREE)
    return ARR_EMP;
  if (m == MAP_BUSY)
    return ARR_SINGLE_BIT | k;
  Pair x = map_arena.items[m];
  uint32_t l = to_arr(x.l, k * 2);
  uint32_t r = to_arr(x.r, k * 2 + 1);
  return arr_concat(l, r);
}
static uint32_t sort(uint32_t a) { return to_arr(to_map(a), 0); }

typedef struct Chk {
  uint32_t nil; // 1 = Cnil
  uint32_t lo, hi, ok, cnt, sum;
} Chk;
static Chk chk_join(Chk a, Chk b) {
  if (a.nil)
    return b;
  if (b.nil)
    return a;
  return (Chk){0,
               a.lo,
               b.hi,
               (a.ok & b.ok) & b2u(a.hi < b.lo),
               a.cnt + b.cnt,
               a.sum + b.sum};
}
static Chk chk(uint32_t a) {
  if (a == ARR_EMP)
    return (Chk){1, 0, 0, 0, 0, 0};
  if (a & ARR_SINGLE_BIT) {
    uint32_t w = a & 16777215u;
    return (Chk){0, w, w, 1, 1, w};
  }
  Pair x = arr_arena.items[a];
  Chk l = chk(x.l);
  Chk r = chk(x.r);
  return chk_join(l, r);
}
static uint32_t chk_out(Chk c) {
  if (c.nil)
    return 0;
  return ((c.sum + c.cnt * 2654435761u) ^ (c.hi + c.lo * 340573321u)) +
         c.ok * 2246822519u;
}

int main(void) {
  printf("%u\n", chk_out(chk(sort(gen(DEPTH, 0)))));
  free(arr_arena.items);
  free(map_arena.items);
}
