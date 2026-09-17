import Base
# Game of Life: Conway soup census (Catagolue-style soup search), ported 1-to-1
# from Bend3's par_gameoflife. 64*2^size random 4x4-toroidal soups, each packed
# in one U32, fork as a balanced batch tree of 2^size 64-soup leaf chunks. Every
# soup runs gens generations of the bit-packed Conway step, then is classified
# by two probe steps -- still life (fixed point), period-2 oscillator, or chaos
# -- and popcounted by a 16-bit SWAR fold. A chunk accumulates population, the
# two class tallies and a board hash in scalar registers, materializing one
# Census per chunk; czip merges censuses up the fork tree and the checksum mixes
# the final census. Counters ride as Nats (no U32 match in Bend4); classify.p1
# is a continuation def (a Bend4 match cannot follow a +local). This replaces
# the older Array-grid port, whose Bend3 counterpart no longer exists.
#
# Sizes (size, gens): small (1, 2) expect 2601177279 (verified against
# a Bend3 C run on the cluster), big (18, 32) expect 2016151040 (from
# the Bend3 header).

type Cls is Data:
  Still{}
  Osc{}
  Chaos{}

type Census is Data:
  Census{pop: U32, still: U32, osc: U32, mix: U32}

def b2u(b: Bool) -> U32:
  match b:
    case False{}:
      0
    case True{}:
      1

def cell_get(board: U32, r: U32, c: U32) -> U32:
  U32.and(U32.shrn(board, U32.to_nat(U32.and(U32.add(U32.mul(U32.and(r, 3), 4), U32.and(c, 3)), 31))), 1)

def neighbor_count(+board: U32, +r: U32, +c: U32) -> U32:
  U32.add(cell_get(board, U32.sub(r, 1), U32.sub(c, 1)), U32.add(cell_get(board, U32.sub(r, 1), c), U32.add(cell_get(board, U32.sub(r, 1), U32.add(c, 1)), U32.add(cell_get(board, r, U32.sub(c, 1)), U32.add(cell_get(board, r, U32.add(c, 1)), U32.add(cell_get(board, U32.add(r, 1), U32.sub(c, 1)), U32.add(cell_get(board, U32.add(r, 1), c), cell_get(board, U32.add(r, 1), U32.add(c, 1)))))))))

def next_dead(n: U32) -> U32:
  b2u(U32.is_eq(n, 3))

def next_alive(+n: U32) -> U32:
  b2u(Bool.or(U32.is_eq(n, 2), U32.is_eq(n, 3)))

def next_cell.go(n: U32, z: Bool) -> U32:
  match z:
    case True{}:
      next_dead(n)
    case False{}:
      next_alive(n)

def next_cell(a: U32, n: U32) -> U32:
  next_cell.go(n, U32.is_zero(a))

def step_cell(+board: U32, +pos: U32) -> U32:
  +rr = U32.shrn(pos, 2n)
  +cc = U32.and(pos, 3)
  alive = cell_get(board, rr, cc)
  neighbors = neighbor_count(board, rr, cc)
  U32.shln(next_cell(alive, neighbors), U32.to_nat(U32.and(pos, 31)))

def step(+b: U32) -> U32:
  U32.or(step_cell(b, 0), U32.or(step_cell(b, 1), U32.or(step_cell(b, 2), U32.or(step_cell(b, 3), U32.or(step_cell(b, 4), U32.or(step_cell(b, 5), U32.or(step_cell(b, 6), U32.or(step_cell(b, 7), U32.or(step_cell(b, 8), U32.or(step_cell(b, 9), U32.or(step_cell(b, 10), U32.or(step_cell(b, 11), U32.or(step_cell(b, 12), U32.or(step_cell(b, 13), U32.or(step_cell(b, 14), step_cell(b, 15))))))))))))))))

def run(n: Nat, board: U32) -> U32:
  match n:
    case 0n:
      board
    case 1n+p:
      run(p, step(board))

# 16-bit SWAR population count
def popcount(+b: U32) -> U32:
  +a = U32.sub(b, U32.and(U32.shrn(b, 1n), 21845))
  +c = U32.add(U32.and(a, 13107), U32.and(U32.shrn(a, 2n), 13107))
  d = U32.and(U32.add(c, U32.shrn(c, 4n)), 3855)
  U32.and(U32.shrn(U32.mul(d, 257), 8n), 31)

def classify.p2(t: Bool) -> Cls:
  match t:
    case True{}:
      Osc{}
    case False{}:
      Chaos{}

def classify.go(t: Bool, n1: U32, b: U32) -> Cls:
  match t:
    case True{}:
      Still{}
    case False{}:
      classify.p2(U32.is_eq(step(n1), b))

def classify.p1(+n1: U32, +b: U32) -> Cls:
  classify.go(U32.is_eq(n1, b), n1, b)

# classify the settled board by two probe steps: fixed point = still
# life, return after two = period-2 oscillator, anything else = chaos
def classify(+b: U32) -> Cls:
  classify.p1(step(b), b)

# one soup: hash the soup index into a 16-bit board, run gens steps
def sim(ix: U32, g: Nat) -> U32:
  run(g, U32.and(U32.mul(ix, 2654435761), 65535))

# class code: Still 0, Osc 1, Chaos 2 (the chunk accumulators update
# branchlessly off this code, so chunk never matches a computed value)
def cls.code(c: Cls) -> U32:
  match c:
    case Still{}:
      0
    case Osc{}:
      1
    case Chaos{}:
      2

# leaf chunk: 64 soups folded into scalar accumulators; the Census
# ctor materializes once per chunk, never per soup
def chunk(+j: Nat, +i: U32, +g: Nat, pa: U32, sa: U32, oa: U32,
          mx: U32) -> Census:
  match j:
    case 0n:
      Census{pa, sa, oa, mx}
    case 1n+p:
      +bd = sim(U32.add(i, U32.from_nat(p)), g)
      +cd = cls.code(classify(bd))
      chunk(p, i, g, U32.add(pa, popcount(bd)),
        U32.add(sa, b2u(U32.is_eq(cd, 0))), U32.add(oa, b2u(U32.is_eq(cd, 1))),
        U32.xor(U32.mul(mx, 2654435761), bd))

def czip(a: Census, b: Census) -> Census:
  match a b:
    case Census{p, s, o, m} Census{q, t, r, n}:
      Census{U32.add(p, q), U32.add(s, t), U32.add(o, r), U32.add(U32.mul(m, 2654435761), n)}

def batch(+d: Nat, +i: U32, +g: Nat) -> Census:
  match d:
    case 0n:
      chunk(64n, i, g, 0, 0, 0, 0)
    case 1n+p:
      a b = batch(p, i, g) batch(p, U32.add(i, U32.shln(64, p)), g)
      czip(a, b)

# final checksum: mix the census fields
def cfin(c: Census) -> U32:
  match c:
    case Census{p, s, o, m}:
      U32.add(U32.mul(U32.add(U32.mul(U32.add(U32.mul(p, 2654435761), s), 2654435761), o), 2654435761), m)

def size() -> Nat:
  18n

def gens() -> Nat:
  32n

# small: size 1n gens 2n expect 2601177279; big expect 2016151040
def main() -> IO(Unit):
  IO.print(U32.show(cfin(batch!(size(), 0, gens()))))
