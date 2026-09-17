// Native C twin of main.bend: recursive block matrix multiply over
// quad-trees with a Freivalds verification pass. Single-threaded, 1-to-1
// with the Bend program: same quad-tree/vector datatypes, same recursive
// block multiply (8 products joined by 4 adds per node), same numerics in
// wrapping u32. ADT nodes live in a pool arena with a freelist; the
// Lf/Qd (Vl/Vn) tag rides in the pointer's low bit, so a node is four
// words: a leaf's value or a branch's kids. Adds consume their inputs
// (reusing the left node in place, freeing the right); generators and
// multiplies allocate.
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

typedef struct Node {
  union {
    uint32_t v;        // leaf payload
    struct Node *k[4]; // branch kids (vec branches use k[0], k[1])
  };
} Node;

typedef struct Node Mat;
typedef struct Node Vec;

// tag bit 0: set = leaf, clear = branch
#define IS_LEAF(p) ((uintptr_t)(p)&1u)
#define PTR(p) ((Node *)((uintptr_t)(p) & ~(uintptr_t)1u))
#define LV(p) (PTR(p)->v)

static Node *pool_free = NULL;
static Node *pool_block = NULL;
static size_t pool_used = 0;
static size_t pool_cap = 0;

static Node *node_alloc(void) {
  if (pool_free != NULL) {
    Node *node = pool_free;
    pool_free = node->k[0];
    return node;
  }
  if (pool_used == pool_cap) {
    pool_cap = 1u << 20;
    pool_block = malloc(pool_cap * sizeof(Node));
    if (pool_block == NULL) {
      fputs("pool exhausted\n", stderr);
      exit(2);
    }
    pool_used = 0;
  }
  return &pool_block[pool_used++];
}

static void node_free(Node *node) {
  node->k[0] = pool_free;
  pool_free = node;
}

static void tree_free(Node *t) {
  Node *node = PTR(t);
  if (!IS_LEAF(t)) {
    tree_free(node->k[0]);
    tree_free(node->k[1]);
    if (node->k[2] != NULL) {
      tree_free(node->k[2]);
      tree_free(node->k[3]);
    }
  }
  node_free(node);
}

static Node *node_leaf(uint32_t v) {
  Node *node = node_alloc();
  node->v = v;
  return (Node *)((uintptr_t)node | 1u);
}

static Mat *mat_quad(Mat *a, Mat *b, Mat *c, Mat *d) {
  Node *node = node_alloc();
  node->k[0] = a;
  node->k[1] = b;
  node->k[2] = c;
  node->k[3] = d;
  return node;
}

static Vec *vec_branch(Vec *l, Vec *r) {
  Node *node = node_alloc();
  node->k[0] = l;
  node->k[1] = r;
  node->k[2] = NULL;
  node->k[3] = NULL;
  return node;
}

// Bool is 0/1
static uint32_t b2u(uint32_t b) {
  return b != 0u ? 1u : 0u;
}

static Mat *mat_gen(uint32_t d, uint32_t s) {
  if (d == 0u) {
    return node_leaf(s % 100u);
  }
  Mat *a = mat_gen(d - 1u, s * 1664525u + 1u);
  Mat *b = mat_gen(d - 1u, s * 214013u + 3u);
  Mat *c = mat_gen(d - 1u, s * 16843009u + 5u);
  Mat *e = mat_gen(d - 1u, s * 48271u + 7u);
  return mat_quad(a, b, c, e);
}

static Vec *vec_gen(uint32_t d, uint32_t s) {
  if (d == 0u) {
    return node_leaf((s * 2654435761u) % 100u + 1u);
  }
  Vec *l = vec_gen(d - 1u, s * 1664525u + 1u);
  Vec *r = vec_gen(d - 1u, s * 214013u + 3u);
  return vec_branch(l, r);
}

// consumes both inputs, reusing the left node in place
static Mat *mat_add(Mat *a, Mat *b) {
  if (IS_LEAF(a)) {
    if (IS_LEAF(b)) {
      LV(a) += LV(b);
      node_free(PTR(b));
      return a;
    }
    LV(a) = 0u;
    tree_free(b);
    return a;
  }
  if (IS_LEAF(b)) {
    LV(b) = 0u;
    tree_free(a);
    return b;
  }
  a->k[0] = mat_add(a->k[0], b->k[0]);
  a->k[1] = mat_add(a->k[1], b->k[1]);
  a->k[2] = mat_add(a->k[2], b->k[2]);
  a->k[3] = mat_add(a->k[3], b->k[3]);
  node_free(b);
  return a;
}

// join of one mul burst: C_ij = P_ij + Q_ij (consumes all eight)
static Mat *mat_add4(Mat *p0, Mat *q0, Mat *p1, Mat *q1, Mat *p2, Mat *q2,
                     Mat *p3, Mat *q3) {
  Mat *c0 = mat_add(p0, q0);
  Mat *c1 = mat_add(p1, q1);
  Mat *c2 = mat_add(p2, q2);
  Mat *c3 = mat_add(p3, q3);
  return mat_quad(c0, c1, c2, c3);
}

// reads both inputs; each node spawns its whole 8-product burst
static Mat *mat_mul(Mat *a, Mat *b) {
  if (IS_LEAF(a)) {
    if (IS_LEAF(b)) {
      return node_leaf(LV(a) * LV(b));
    }
    return node_leaf(0u);
  }
  if (IS_LEAF(b)) {
    return node_leaf(0u);
  }
  Mat *p0 = mat_mul(a->k[0], b->k[0]);
  Mat *q0 = mat_mul(a->k[1], b->k[2]);
  Mat *p1 = mat_mul(a->k[0], b->k[1]);
  Mat *q1 = mat_mul(a->k[1], b->k[3]);
  Mat *p2 = mat_mul(a->k[2], b->k[0]);
  Mat *q2 = mat_mul(a->k[3], b->k[2]);
  Mat *p3 = mat_mul(a->k[2], b->k[1]);
  Mat *q3 = mat_mul(a->k[3], b->k[3]);
  return mat_add4(p0, q0, p1, q1, p2, q2, p3, q3);
}

// consumes both inputs, reusing the left node in place
static Vec *vec_add(Vec *x, Vec *y) {
  if (IS_LEAF(x)) {
    if (IS_LEAF(y)) {
      LV(x) += LV(y);
      node_free(PTR(y));
      return x;
    }
    LV(x) = 0u;
    tree_free(y);
    return x;
  }
  if (IS_LEAF(y)) {
    LV(y) = 0u;
    tree_free(x);
    return y;
  }
  x->k[0] = vec_add(x->k[0], y->k[0]);
  x->k[1] = vec_add(x->k[1], y->k[1]);
  node_free(y);
  return x;
}

// join of one mvm burst (consumes all four)
static Vec *vec_add2(Vec *t0, Vec *t1, Vec *t2, Vec *t3) {
  return vec_branch(vec_add(t0, t1), vec_add(t2, t3));
}

// reads both inputs; [[a,b],[c,d]] * (l,h) = (a*l + b*h, c*l + d*h)
static Vec *mat_vec_mul(Mat *m, Vec *v) {
  if (IS_LEAF(m)) {
    if (IS_LEAF(v)) {
      return node_leaf(LV(m) * LV(v));
    }
    return node_leaf(0u);
  }
  if (IS_LEAF(v)) {
    return node_leaf(0u);
  }
  Vec *t0 = mat_vec_mul(m->k[0], v->k[0]);
  Vec *t1 = mat_vec_mul(m->k[1], v->k[1]);
  Vec *t2 = mat_vec_mul(m->k[2], v->k[0]);
  Vec *t3 = mat_vec_mul(m->k[3], v->k[1]);
  return vec_add2(t0, t1, t2, t3);
}

static uint32_t mat_cksum(Mat *m) {
  if (IS_LEAF(m)) {
    return LV(m);
  }
  uint32_t p = mat_cksum(m->k[0]);
  uint32_t q = mat_cksum(m->k[1]);
  uint32_t r = mat_cksum(m->k[2]);
  uint32_t s = mat_cksum(m->k[3]);
  return p + q + r + s;
}

// or-fold of elementwise xor: 0 iff the vectors are identical
static uint32_t vec_dif(Vec *x, Vec *y) {
  if (IS_LEAF(x)) {
    if (IS_LEAF(y)) {
      return LV(x) ^ LV(y);
    }
    return 1u;
  }
  if (IS_LEAF(y)) {
    return 1u;
  }
  uint32_t l = vec_dif(x->k[0], y->k[0]);
  uint32_t r = vec_dif(x->k[1], y->k[1]);
  return l | r;
}

// one round: generate A, B, r; C = A*B; Freivalds-verify C*r == A*(B*r)
static uint32_t round_run(uint32_t d, uint32_t s) {
  Mat *a = mat_gen(d, s + 1u);
  Mat *b = mat_gen(d, s + 2u);
  Vec *r = vec_gen(d, s + 3u);
  Mat *c = mat_mul(a, b);
  uint32_t k = mat_cksum(c);
  Vec *t1 = mat_vec_mul(c, r);
  Vec *u = mat_vec_mul(b, r);
  Vec *t2 = mat_vec_mul(a, u);
  uint32_t v = vec_dif(t1, t2);
  tree_free(a);
  tree_free(b);
  tree_free(r);
  tree_free(c);
  tree_free(t1);
  tree_free(u);
  tree_free(t2);
  return (k ^ (s * 2654435761u)) + b2u(v == 0u ? 1u : 0u);
}

static uint32_t batch_leaf_go(uint32_t t, uint32_t d, uint32_t pp) {
  if (t == 0u) {
    return 0u;
  }
  return round_run(d, pp * 2654435761u);
}

static uint32_t batch_leaf(uint32_t pp, uint32_t n, uint32_t d) {
  return batch_leaf_go(pp < n ? 1u : 0u, d, pp);
}

// batch tree over the round index space: leaf i runs one round when
// p < nchain, p = the leaf's odd-multiplier permuted index (seed =
// hashed p, so the live chain set -- and the checksum -- is the same
// for any spread)
static uint32_t batch_run(uint32_t bg, uint32_t i, uint32_t n, uint32_t m,
                          uint32_t d) {
  if (bg == 0u) {
    return batch_leaf((i * 2654435761u) & m, n, d);
  }
  uint32_t x = batch_run(bg - 1u, i, n, m, d);
  uint32_t y = batch_run(bg - 1u, i + (1u << (bg - 1u)), n, m, d);
  return x + y;
}

int main(void) {
  uint32_t size = 7u;
  uint32_t blog = 9u;
  uint32_t nchain = 384u;
  uint32_t mm = (1u << blog) - 1u;
  printf("%u\n", batch_run(blog, 0u, nchain, mm, size));
  return 0;
}
