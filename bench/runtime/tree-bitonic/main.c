// Native C twin of main.bend: same tree-shaped bitonic sorting
// network, key generator and Stat verification scan, single-threaded,
// one C function per Bend function. A Term is a tagged 64-bit
// reference: bit 32 marks the Leaf constructor (v rides immediate in
// the low word), Node terms index an arena of {l, r} pairs with a
// freelist. Each match consumes its node (mirroring the linear
// semantics) and warp_zip rewrites the consumed pairs in place, so
// peak memory stays ~n nodes across the whole sort.
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#ifndef SIZE
#define SIZE 23
#endif

typedef uint64_t Term;
#define TREE_LEAF (1ull << 32)
typedef struct Node {
  Term a, b;
} Node;
typedef struct TreeArena {
  Node *items;
  size_t length, capacity;
  uint32_t free_head; // freelist threaded through .a
} TreeArena;

#define TREE_NIL 0xFFFFFFFFu

static uint32_t tree_arena_push(TreeArena *arena, Node value) {
  if (arena->free_head != TREE_NIL) {
    uint32_t i = arena->free_head;
    arena->free_head = (uint32_t)arena->items[i].a;
    arena->items[i] = value;
    return i;
  }
  if (arena->length == arena->capacity) {
    size_t n = arena->capacity ? arena->capacity * 2 : 1024;
    Node *p = realloc(arena->items, n * sizeof(*p));
    if (!p) {
      fputs("Tree arena exhausted\n", stderr);
      exit(2);
    }
    arena->items = p;
    arena->capacity = n;
  }
  uint32_t i = (uint32_t)arena->length++;
  arena->items[i] = value;
  return i;
}
static void tree_drop(TreeArena *arena, uint32_t i) {
  arena->items[i].a = arena->free_head;
  arena->free_head = i;
}
static Term tree_leaf(uint32_t v) { return TREE_LEAF | v; }
static Term tree_node(TreeArena *a, Term l, Term r) {
  return tree_arena_push(a, (Node){l, r});
}
static int is_leaf(Term t) { return (t & TREE_LEAF) != 0; }

static uint32_t word_prng(uint32_t x) {
  uint32_t b = x ^ (x << 13);
  uint32_t d = b ^ (b >> 17);
  return d ^ (d << 5);
}
static uint32_t word_key(uint32_t i) { return word_prng((i + 1u) * 2654435761u); }

static Term tree_warp_leaf_go(TreeArena *a, uint32_t x, uint32_t y,
                              uint32_t t) {
  if (t)
    return tree_node(a, tree_leaf(y), tree_leaf(x));
  return tree_node(a, tree_leaf(x), tree_leaf(y));
}
static Term tree_warp_leaf(TreeArena *a, uint32_t x, uint32_t y, uint32_t s) {
  return tree_warp_leaf_go(a, x, y, s ^ (x > y ? 1u : 0u));
}
// warp_zip: reuse wa, wb as the zipped children
static Term tree_warp_zip(TreeArena *a, Term wa, Term wb) {
  if (!is_leaf(wa) && !is_leaf(wb)) {
    uint32_t i = (uint32_t)wa, j = (uint32_t)wb;
    Term a1 = a->items[i].b;
    a->items[i].b = a->items[j].a;
    a->items[j].a = a1;
    return tree_node(a, wa, wb);
  }
  return tree_leaf(0);
}
static Term tree_warp(TreeArena *a, Term x, Term y, uint32_t s) {
  if (is_leaf(x) && is_leaf(y))
    return tree_warp_leaf(a, (uint32_t)x, (uint32_t)y, s);
  if (is_leaf(x) != is_leaf(y))
    return tree_leaf(0);
  uint32_t i = (uint32_t)x, j = (uint32_t)y;
  Node p = a->items[i], q = a->items[j];
  tree_drop(a, i);
  tree_drop(a, j);
  Term wa = tree_warp(a, p.a, q.a, s);
  Term wb = tree_warp(a, p.b, q.b, s);
  return tree_warp_zip(a, wa, wb);
}
// warp of a whole subtree: compare-and-swap its root pair
static Term tree_warp_node(TreeArena *a, Term t, uint32_t s) {
  if (is_leaf(t))
    return t;
  uint32_t i = (uint32_t)t;
  Node n = a->items[i];
  tree_drop(a, i);
  return tree_warp(a, n.a, n.b, s);
}
// bitonic merge, root pair already warped by the caller
static Term tree_flow(TreeArena *a, uint32_t d, uint32_t s, Term w) {
  if (d == 0)
    return w;
  if (is_leaf(w))
    return w;
  uint32_t i = (uint32_t)w;
  Node n = a->items[i];
  Term fa = tree_flow(a, d - 1, s, tree_warp_node(a, n.a, s));
  Term fb = tree_flow(a, d - 1, s, tree_warp_node(a, n.b, s));
  a->items[i] = (Node){fa, fb};
  return w;
}
static Term tree_bsort(TreeArena *a, uint32_t d, uint32_t s, uint32_t x) {
  if (d == 0)
    return tree_leaf(word_key(x));
  Term sa = tree_bsort(a, d - 1, 0, x * 2 + 1);
  Term sb = tree_bsort(a, d - 1, 1, x * 2);
  return tree_flow(a, d - 1, s, tree_warp(a, sa, sb, s));
}

typedef struct Stat {
  uint32_t lo, hi, ok, mx;
} Stat;
static Stat stat_join_go(uint32_t alo, uint32_t bhi, uint32_t aok, uint32_t bok,
                         uint32_t amx, uint32_t bmx, uint32_t t) {
  return (Stat){alo, bhi, t ? (aok & bok) : 0, amx * 2654435761u + bmx};
}
static Stat stat_join(Stat a, Stat b) {
  return stat_join_go(a.lo, b.hi, a.ok, b.ok, a.mx, b.mx,
                      a.hi <= b.lo ? 1u : 0u);
}
static Stat tree_scan(TreeArena *a, Term t) {
  if (is_leaf(t)) {
    uint32_t v = (uint32_t)t;
    return (Stat){v, v, 1, v};
  }
  Node n = a->items[(uint32_t)t];
  Stat l = tree_scan(a, n.a);
  Stat r = tree_scan(a, n.b);
  return stat_join(l, r);
}
static uint32_t stat_out(Stat s) {
  return ((s.mx * 2654435761u) ^ (s.hi + s.lo * 340573321u)) +
         s.ok * 2246822519u;
}

int main(void) {
  size_t cap = ((size_t)1 << SIZE) + 1024;
  TreeArena arena = {malloc(cap * sizeof(Node)), 0, cap, TREE_NIL};
  if (!arena.items)
    return 2;
  Term t = tree_bsort(&arena, SIZE, 0, 0);
  printf("%u\n", stat_out(tree_scan(&arena, t)));
  free(arena.items);
}
