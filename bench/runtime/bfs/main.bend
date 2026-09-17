import Base
# BFS: breadth-first search over 2^SIZE independent 32x32 grid mazes,
# the suite's graph-traversal case: a flat Array<U32> queue with head
# and tail indices and a flat Array<U32> distance map, walked in the
# textbook shape. Maze m takes its seed from the Knuth-mixed index.
# fill stamps its 1024-cell grid (index y*32 + x) with 1 for an open
# cell and 0 for a wall: a cell is a wall when the xorshift hash of
# seed and cell, mod 100, is under 30; the start, cell 0, is always
# open. The distance map starts at 4294967295 (unseen) with cell 0 at
# 0, and the queue holds cell 0. bfs then pops cells, fuel-bounded by
# the cell count (a cell is pushed once at most): each pop reads the
# head cell and its distance and looks at its four neighbours (left,
# right, up, down, with bounds checks); an open, unseen neighbour gets
# its distance stamped and is pushed at the tail. The whole state rides
# in one St record (grid, queue, dist, head, tail); a pop answers the
# state plus whether the queue still holds a cell, and the loop stops
# on that bit. fold mixes every cell into the leaf checksum (acc =
# acc * 2654435761 ^ (reached ? dist * (c + 1) : 0)) and seals it with
# the reached count; leaf checksums sum up the fork tree.
#
# Spelling notes: g[i] reads are Array.get (the array rides back in a
# pair, opened by the next stage def), g[i] <- v writes are Array.set;
# every loop counts on a Nat (no U32 match in Bend4); a decision is a
# Bool handed to the def that matches it; words used twice ride +
# binders (St declares head and tail +, so an opened record hands them
# out reusable).
#
# Sizes: small batch!(4n, 0) expect 512822161 (all four lanes agree,
# and at 12n, 13n and 15n too), big batch!(size(), 0) with size() =
# 19n expect 651176970 (the C twin takes ~3.4 s: filled from the cluster).

type St is Type:
  St{g: Array<U32>, q: Array<U32>, d: Array<U32>, +head: U32, +tail: U32}

def b2u(b: Bool) -> U32:
  match b:
    case False{}:
      0
    case True{}:
      1

# xorshift: x ^= x<<13; x ^= x>>17; x ^= x<<5
def prng(+x: U32) -> U32:
  +b = U32.xor(x, U32.shln(x, 13n))
  +d = U32.xor(b, U32.shrn(b, 17n))
  U32.xor(d, U32.shln(d, 5n))

# 1 when cell c of the maze seeded s is open: the start always, any
# other cell when its hash mod 100 is 30 or more (30% walls)
def open(s: U32, +c: U32) -> U32:
  h = prng(U32.xor(s, U32.mul(U32.inc(c), 340573321)))
  b2u(Bool.or(U32.is_zero(c), U32.is_ge(U32.mod(h, 100), 30)))

# fill the grid: one write per cell, ascending
def fill(+j: Nat, +s: U32, g: Array<U32>) -> Array<U32>:
  match j:
    case 0n:
      g
    case 1n+p:
      +c = U32.sub(1023, U32.from_nat(p))
      fill(p, s, g[c] <- open(s, c))

# the neighbour is open: push it unless seen (stamp its distance,
# queue it at the tail)
def look.push(+n: U32, v: U32, seen: Bool, st: St) -> St:
  match seen:
    case True{}:
      st
    case False{}:
      St{g, q, d, head, tail} = st
      St{g, q[tail] <- n, d[n] <- v, head, U32.inc(tail)}

def look.seen(+n: U32, v: U32, g: Array<U32>, q: Array<U32>, head: U32,
              tail: U32, r: Array<U32> & U32) -> St:
  (d, dn) = r
  look.push(n, v, U32.is_ne(dn, 4294967295), St{g, q, d, head, tail})

# the neighbour is in bounds: skip a wall, else read its distance
def look.wall(+n: U32, v: U32, wall: Bool, st: St) -> St:
  match wall:
    case True{}:
      st
    case False{}:
      St{g, q, d, head, tail} = st
      look.seen(n, v, g, q, head, tail, d[n])

def look.open(+n: U32, v: U32, q: Array<U32>, d: Array<U32>, head: U32,
              tail: U32, r: Array<U32> & U32) -> St:
  (g, o) = r
  look.wall(n, v, U32.is_zero(o), St{g, q, d, head, tail})

# one neighbour n at distance v: skip it out of bounds, a wall or
# seen; else stamp its distance and push it
def look(+n: U32, v: U32, inb: Bool, st: St) -> St:
  match inb:
    case False{}:
      st
    case True{}:
      St{g, q, d, head, tail} = st
      look.open(n, v, q, d, head, tail, g[n])

# the four neighbours of cell c at distance v: left, right, up, down
def look4(+c: U32, +v: U32, st: St) -> St:
  +x = U32.and(c, 31)
  +y = U32.shrn(c, 5n)
  s1 = look(U32.sub(c, 1), v, U32.is_gt(x, 0), st)
  s2 = look(U32.inc(c), v, U32.is_lt(x, 31), s1)
  s3 = look(U32.sub(c, 32), v, U32.is_gt(y, 0), s2)
  look(U32.add(c, 32), v, U32.is_lt(y, 31), s3)

# the pop's answer: the state, and whether the queue still holds a cell
def pop.done(st: St) -> St & Bool:
  St{g, q, d, head, tail} = st
  (St{g, q, d, head, tail}, U32.is_lt(head, tail))

def pop.dist(g: Array<U32>, q: Array<U32>, c: U32, head: U32, tail: U32,
             r: Array<U32> & U32) -> St & Bool:
  (d, dc) = r
  pop.done(look4(c, U32.inc(dc), St{g, q, d, head, tail}))

def pop.cell(g: Array<U32>, d: Array<U32>, head: U32, tail: U32,
             r: Array<U32> & U32) -> St & Bool:
  (q, +c) = r
  pop.dist(g, q, c, head, tail, d[c])

# one pop: take the head cell and its distance, look at its four
# neighbours, then report whether the queue still holds a cell
def pop(st: St) -> St & Bool:
  St{g, q, d, head, tail} = st
  pop.cell(g, d, U32.inc(head), tail, q[head])

# the search loop, fuel-bounded by the cell count: the pop's answer
# rides in as the pair r, and the loop stops when the queue drains
def bfs(f: Nat, r: St & Bool) -> St:
  match f:
    case 0n:
      (st, more) = r
      st
    case 1n+p:
      (st, more) = r
      match more:
        case False{}:
          st
        case True{}:
          bfs(p, pop(st))

# the leaf checksum: every cell in turn, the current read riding in as
# the pair r (the last step issues one masked dead read); a reached
# cell mixes its distance position-weighted and counts one
def fold(+j: Nat, r: Array<U32> & U32, acc: U32, cnt: U32) -> U32:
  match j:
    case 0n:
      U32.xor(acc, U32.mul(cnt, 2246822519))
    case 1n+p:
      (d, +v) = r
      +c = U32.sub(1023, U32.from_nat(p))
      +hit = b2u(U32.is_ne(v, 4294967295))
      k = U32.mul(hit, U32.mul(v, U32.inc(c)))
      m = U32.xor(U32.mul(acc, 2654435761), k)
      fold(p, d[U32.inc(c)], m, U32.add(cnt, hit))

def finish(st: St) -> U32:
  St{g, q, d, head, tail} = st
  fold(1024n, d[0], 0, 0)

# one maze: fill the grid, seed the search with cell 0 at distance 0,
# search, fold
def maze(m: U32) -> U32:
  s = U32.mul(U32.inc(m), 2654435761)
  g = fill(1024n, s, [0 : U32*1024n])
  q = [0 : U32*1024n]
  d = [4294967295 : U32*1024n]
  finish(bfs(1024n, (St{g, q, d[0] <- 0, 0, 1}, True{})))

# batch tree over the maze index space: leaf i searches maze i
def batch(+k: Nat, +i: U32) -> U32:
  match k:
    case 0n:
      maze(i)
    case 1n+p:
      a b = batch(p, i) batch(p, U32.add(i, U32.shln(1, p)))
      U32.add(a, b)

def size() -> Nat:
  19n

# small: batch!(4n, 0) expect 512822161; big: batch!(size(), 0)
# expect 651176970
def main() -> IO(Unit):
  IO.print(U32.show(batch!(size(), 0)))
