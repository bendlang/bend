// Single-threaded TypeScript twin of main.bend. Same
// algorithms over the same expression-tree ADT: expr_gen materializes
// each depth-5 candidate AST from the xorshift32 stream (plain class
// nodes), expr_eval is the recursive pattern-matching interpreter
// (Bend's eval walks the tree; value recursion, order and u32
// numerics are identical), expr_size adds the
// parsimony penalty, batch_run folds the tournament, seed_climb
// hill-climbs the winner. Checksum printed as one u32.
// Expected at SIZE=18, PTS=110: 2383953211.
const SIZE = 18,
  PTS = 110,
  ROUNDS = 32;

const EXPR_VAR = 0,
  EXPR_LIT = 1,
  EXPR_ADD = 2,
  EXPR_SUB = 3,
  EXPR_MUL = 4,
  EXPR_XOR = 5;

class Expr {
  tag: number;
  v: number;
  a: Expr | null;
  b: Expr | null;
  constructor(tag: number, v: number, a: Expr | null, b: Expr | null) {
    this.tag = tag;
    this.v = v;
    this.a = a;
    this.b = b;
  }
}

function word_prng(x: number): number {
  const b = (x ^ (x << 13)) >>> 0;
  const d = (b ^ (b >>> 17)) >>> 0;
  return (d ^ (d << 5)) >>> 0;
}

function value_select(t: number, x: number, y: number): number {
  return t === 0 ? x : y;
}

function value_difference(a: number, b: number): number {
  return value_select(a < b ? 1 : 0, (a - b) >>> 0, (b - a) >>> 0);
}

// materialize a candidate AST straight off the hash stream
function expr_gen(d: number, h: number): Expr {
  if (d === 0) {
    if (((h >>> 8) & 1) === 0) {
      return new Expr(EXPR_VAR, 0, null, null);
    }
    return new Expr(EXPR_LIT, h & 255, null, null);
  }
  const a = expr_gen(d - 1, word_prng((h ^ 2654435761) >>> 0));
  const b = expr_gen(d - 1, word_prng((h + 340573321) >>> 0));
  switch (h % 4) {
    case 0:
      return new Expr(EXPR_ADD, 0, a, b);
    case 1:
      return new Expr(EXPR_SUB, 0, a, b);
    case 2:
      return new Expr(EXPR_MUL, 0, a, b);
    default:
      return new Expr(EXPR_XOR, 0, a, b);
  }
}

// pattern-matching interpreter: value of the candidate at x
function expr_eval(e: Expr, x: number): number {
  switch (e.tag) {
    case EXPR_VAR:
      return x;
    case EXPR_LIT:
      return e.v;
    case EXPR_ADD:
      return (expr_eval(e.a!, x) + expr_eval(e.b!, x)) >>> 0;
    case EXPR_SUB:
      return (expr_eval(e.a!, x) - expr_eval(e.b!, x)) >>> 0;
    case EXPR_MUL:
      return Math.imul(expr_eval(e.a!, x), expr_eval(e.b!, x)) >>> 0;
    default:
      return (expr_eval(e.a!, x) ^ expr_eval(e.b!, x)) >>> 0;
  }
}

// parsimony: AST node count
function expr_size(e: Expr): number {
  if (e.tag === EXPR_VAR || e.tag === EXPR_LIT) {
    return 1;
  }
  return (1 + ((expr_size(e.a!) + expr_size(e.b!)) >>> 0)) >>> 0;
}

// dataset fold: error sum over x = 0..j-1, then the parsimony penalty
function fitness_loop(j: number, e: Expr, acc: number): number {
  while (j !== 0) {
    const x = j - 1;
    const p = expr_eval(e, x);
    const t = (Math.imul(x, x) + (Math.imul(3, x) + 7)) >>> 0;
    acc = (acc + value_difference(p, t)) >>> 0;
    j = x;
  }
  return (acc + Math.imul(expr_size(e), 8)) >>> 0;
}

class Sel {
  fit: number;
  seed: number;
  sum: number;
  constructor(fit: number, seed: number, sum: number) {
    this.fit = fit;
    this.seed = seed;
    this.sum = sum;
  }
}

function candidate_evaluate(s: number, pts: number): Sel {
  const t = expr_gen(5, word_prng(s));
  const f = fitness_loop(pts, t, 0);
  return new Sel(f, s, (f ^ Math.imul(s, 2654435761)) >>> 0);
}

// tournament: keep the lower-fitness candidate, sum the checksums
function winner_pick(a: Sel, b: Sel): Sel {
  const w = a.fit < b.fit ? 1 : 0;
  return new Sel(
    value_select(w, b.fit, a.fit),
    value_select(w, b.seed, a.seed),
    (a.sum + b.sum) >>> 0,
  );
}

function batch_run(d: number, s: number, pts: number): Sel {
  if (d === 0) {
    return candidate_evaluate(word_prng(s), pts);
  }
  const a = batch_run(d - 1, (Math.imul(s, 1664525) + 1) >>> 0, pts);
  const b = batch_run(d - 1, (Math.imul(s, 214013) + 3) >>> 0, pts);
  return winner_pick(a, b);
}

// hill-climb the tournament winner: mutate the seed, keep improvements
function seed_climb(r: number, bs: number, bf: number, pts: number): number {
  while (r !== 0) {
    const w0 = candidate_evaluate(
      word_prng((bs ^ Math.imul(r, 40503)) >>> 0),
      pts,
    );
    const w = w0.fit < bf ? 1 : 0;
    bs = value_select(w, bs, w0.seed);
    bf = value_select(w, bf, w0.fit);
    r -= 1;
  }
  return (bf ^ Math.imul(bs, 2654435761)) >>> 0;
}

function benchmark_run(): number {
  const w1 = batch_run(SIZE, 42, PTS);
  return (seed_climb(ROUNDS, w1.seed, w1.fit, PTS) + w1.sum) >>> 0;
}
console.log(benchmark_run());
