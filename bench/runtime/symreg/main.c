// Single-threaded C twin of main.bend. Same
// algorithms over the same expression-tree ADT: expr_gen materializes
// each depth-5 candidate AST from the xorshift32 stream into a bump
// arena (reset per candidate, no per-node malloc; nodes hold child
// pointers, matching Bend's boxed Expr), expr_eval is the recursive
// pattern-matching interpreter (Bend's eval walks the tree; the value
// recursion, order and u32 numerics are identical), expr_size adds
// the parsimony penalty, batch_run folds the tournament over the
// population, seed_climb hill-climbs the winner. Checksum printed as
// one u32.
// Build: cc -O3 main.c
// Expected at SIZE=18, PTS=110: 2383953211.

#include <stdint.h>
#include <stdio.h>

#define SIZE 18u
#define PTS 110u
#define ROUNDS 32u

// Expr ADT: bump arena of tagged nodes (a full depth-5 tree is 63 nodes)
enum { EXPR_VAR, EXPR_LIT, EXPR_ADD, EXPR_SUB, EXPR_MUL, EXPR_XOR };
typedef struct Expr Expr;
struct Expr {
  uint32_t tag, lit;
  const Expr *a, *b;
};
static Expr expr_arena[64];
static uint32_t expr_arena_len;

static const Expr *expr_push(uint32_t tag, uint32_t lit, const Expr *a,
                             const Expr *b) {
  Expr *n = &expr_arena[expr_arena_len++];
  *n = (Expr){tag, lit, a, b};
  return n;
}

static uint32_t word_prng(uint32_t x) {
  uint32_t b = x ^ (x << 13);
  uint32_t d = b ^ (b >> 17);
  return d ^ (d << 5);
}

static uint32_t value_select(uint32_t t, uint32_t x, uint32_t y) {
  return t == 0u ? x : y;
}

static uint32_t value_difference(uint32_t a, uint32_t b) {
  return value_select(a < b, a - b, b - a);
}

static const Expr *expr_node(uint32_t o, const Expr *a, const Expr *b) {
  switch (o) {
  case 0u:
    return expr_push(EXPR_ADD, 0u, a, b);
  case 1u:
    return expr_push(EXPR_SUB, 0u, a, b);
  case 2u:
    return expr_push(EXPR_MUL, 0u, a, b);
  default:
    return expr_push(EXPR_XOR, 0u, a, b);
  }
}

// materialize a candidate AST straight off the hash stream
static const Expr *expr_gen_leaf(uint32_t h, uint32_t z) {
  if (z)
    return expr_push(EXPR_VAR, 0u, 0, 0);
  return expr_push(EXPR_LIT, h & 255u, 0, 0);
}

static const Expr *expr_gen(uint32_t d, uint32_t h) {
  if (d == 0u)
    return expr_gen_leaf(h, ((h >> 8) & 1u) == 0u);
  const Expr *a = expr_gen(d - 1u, word_prng(h ^ 2654435761u));
  const Expr *b = expr_gen(d - 1u, word_prng(h + 340573321u));
  return expr_node(h % 4u, a, b);
}

// pattern-matching interpreter: value of the candidate at x
static uint32_t expr_eval(const Expr *e, uint32_t x) {
  switch (e->tag) {
  case EXPR_VAR:
    return x;
  case EXPR_LIT:
    return e->lit;
  case EXPR_ADD:
    return expr_eval(e->a, x) + expr_eval(e->b, x);
  case EXPR_SUB:
    return expr_eval(e->a, x) - expr_eval(e->b, x);
  case EXPR_MUL:
    return expr_eval(e->a, x) * expr_eval(e->b, x);
  default:
    return expr_eval(e->a, x) ^ expr_eval(e->b, x);
  }
}

// parsimony: AST node count
static uint32_t expr_size(const Expr *e) {
  switch (e->tag) {
  case EXPR_VAR:
    return 1u;
  case EXPR_LIT:
    return 1u;
  case EXPR_ADD:
    return 1u + (expr_size(e->a) + expr_size(e->b));
  case EXPR_SUB:
    return 1u + (expr_size(e->a) + expr_size(e->b));
  case EXPR_MUL:
    return 1u + (expr_size(e->a) + expr_size(e->b));
  default:
    return 1u + (expr_size(e->a) + expr_size(e->b));
  }
}

// dataset fold: error sum over x = 0..j-1, then the parsimony penalty
static uint32_t fitness_loop(uint32_t j, const Expr *e, uint32_t acc) {
  if (j == 0u)
    return acc + expr_size(e) * 8u;
  uint32_t x = j - 1u;
  uint32_t p = expr_eval(e, x);
  uint32_t t = x * x + (3u * x + 7u);
  return fitness_loop(x, e, acc + value_difference(p, t));
}

typedef struct {
  uint32_t fit, seed, sum;
} Sel;

static Sel candidate_evaluate(uint32_t s, uint32_t pts) {
  expr_arena_len = 0u;
  const Expr *t = expr_gen(5u, word_prng(s));
  uint32_t f = fitness_loop(pts, t, 0u);
  return (Sel){f, s, f ^ (s * 2654435761u)};
}

// tournament: keep the lower-fitness candidate, sum the checksums
static Sel winner_pick(Sel a, Sel b) {
  uint32_t w = a.fit < b.fit;
  return (Sel){value_select(w, b.fit, a.fit), value_select(w, b.seed, a.seed),
               a.sum + b.sum};
}

static Sel batch_run(uint32_t d, uint32_t s, uint32_t pts) {
  if (d == 0u)
    return candidate_evaluate(word_prng(s), pts);
  Sel a = batch_run(d - 1u, s * 1664525u + 1u, pts);
  Sel b = batch_run(d - 1u, s * 214013u + 3u, pts);
  return winner_pick(a, b);
}

// hill-climb the tournament winner: mutate the seed, keep improvements
static uint32_t seed_climb(uint32_t r, uint32_t bs, uint32_t bf,
                           uint32_t pts) {
  if (r == 0u)
    return bf ^ (bs * 2654435761u);
  Sel cn = candidate_evaluate(word_prng(bs ^ (r * 40503u)), pts);
  uint32_t w = cn.fit < bf;
  return seed_climb(r - 1u, value_select(w, bs, cn.seed),
                    value_select(w, bf, cn.fit), pts);
}

static uint32_t run_finish(uint32_t r, uint32_t p, Sel t) {
  return seed_climb(r, t.seed, t.fit, p) + t.sum;
}

static uint32_t run(uint32_t d, uint32_t s0, uint32_t r, uint32_t p) {
  return run_finish(r, p, batch_run(d, s0, p));
}

int main(void) {
  printf("%u\n", run(SIZE, 42u, ROUNDS, PTS));
  return 0;
}
