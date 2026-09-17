import Base
# editdist: Levenshtein edit distance by dynamic programming over flat
# Array<U32> rows -- the suite's arrays-of-words case. 2^K independent
# pairs fork as a balanced batch tree. Pair p hashes its index into an
# xorshift seed and draws two sequences of N = 256 symbols over a
# 4-letter alphabet (a symbol is the low two bits of the stream; the
# second stream starts at the first seed times an odd constant), each
# written slot by slot into its own 256-slot Array<U32>. The DP walks
# the N x N cell grid with two rolling 512-slot rows, prev and cur:
# prev[j] = j at the start; row i reads a[i] once, writes cur[0] =
# i + 1, then for each j in 0..N-1 reads b[j], prev[j], prev[j+1] and
# cur[j] and writes cur[j+1] = min(prev[j+1] + 1, cur[j] + 1, prev[j]
# + cost), cost 0 when a[i] == b[j] and 1 otherwise; when the row
# ends the rows swap roles. The distance is prev[N] after the last
# row. A pair's checksum mixes its distance with its index; pair
# checksums sum up the fork tree. Knob: K (2^K pairs, 2x per notch).
#
# Spelling notes: `x[i]` reads are Array.get(U32, x, i), which hands
# the array back with the word as a pair, destructured at the top of
# the next stage def (a Bend4 match cannot scrutinize a computed
# value); `x[i] <- v` writes hand the array back alone. The four live
# arrays ride together in the Dp record (a Type, so it may hold
# arrays), opened by pattern at each cell and rebuilt after its write.
# Loop counters are Nats (no U32 match in Bend4) with the U32 index
# alongside; min is a Bool match on U32.is_lt; cost is b2u of
# U32.is_ne.
#
# Sizes: small K = 2n (expect 2065873279, verified against the C
# twin), big K = 15n (expect 2229810577).

type Dp is Type:
  Dp{a: Array<U32>, b: Array<U32>, prev: Array<U32>, cur: Array<U32>}

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

def umin.go(x: U32, y: U32, lt: Bool) -> U32:
  match lt:
    case True{}:
      x
    case False{}:
      y

def umin(+x: U32, +y: U32) -> U32:
  umin.go(x, y, U32.is_lt(x, y))

# draw one sequence: step the stream, write its low two bits at slot k
def gen(+j: Nat, +k: U32, +s: U32, x: Array<U32>) -> Array<U32>:
  match j:
    case 0n:
      x
    case 1n+q:
      +s2 = prng(s)
      gen(q, U32.inc(k), s2, x[k] <- U32.and(s2, 3))

# prev[k] = k: the row of the empty prefix
def init(+j: Nat, +k: U32, x: Array<U32>) -> Array<U32>:
  match j:
    case 0n:
      x
    case 1n+q:
      init(q, U32.inc(k), x[k] <- k)

# one DP cell at column j: 4 reads + 1 write, each read's pair riding
# into the next stage def; the last stage rebuilds the state record
def cell.f4(+j: U32, cost: U32, diag: U32, up: U32, a: Array<U32>,
            b: Array<U32>, prev: Array<U32>, r: Array<U32> & U32) -> Dp:
  (cur, left) = r
  v = umin(umin(U32.inc(up), U32.inc(left)), U32.add(diag, cost))
  Dp{a, b, prev, cur[U32.inc(j)] <- v}

def cell.f3(+j: U32, cost: U32, diag: U32, a: Array<U32>, b: Array<U32>,
            cur: Array<U32>, r: Array<U32> & U32) -> Dp:
  (prev, up) = r
  cell.f4(j, cost, diag, up, a, b, prev, Array.get(U32, cur, j))

def cell.f2(+j: U32, cost: U32, a: Array<U32>, b: Array<U32>, cur: Array<U32>,
            r: Array<U32> & U32) -> Dp:
  (prev, diag) = r
  cell.f3(j, cost, diag, a, b, cur, Array.get(U32, prev, U32.inc(j)))

def cell.f1(+j: U32, ai: U32, a: Array<U32>, prev: Array<U32>, cur: Array<U32>,
            r: Array<U32> & U32) -> Dp:
  (b, bj) = r
  cell.f2(j, b2u(U32.is_ne(ai, bj)), a, b, cur, Array.get(U32, prev, j))

def cell(+j: U32, ai: U32, st: Dp) -> Dp:
  Dp{a, b, prev, cur} = st
  cell.f1(j, ai, a, prev, cur, Array.get(U32, b, j))

# one DP row: N cells in ascending column order; when the row ends
# the rows swap roles
def row(+n: Nat, +j: U32, +ai: U32, st: Dp) -> Dp:
  match n:
    case 0n:
      Dp{a, b, prev, cur} = st
      Dp{a, b, cur, prev}
    case 1n+q:
      row(q, U32.inc(j), ai, cell(j, ai, st))

# row i's prologue: read a[i] (its pair rides into dp.f1), write
# cur[0] = i + 1, then run the row
def dp.f1(+i: U32, b: Array<U32>, prev: Array<U32>, cur: Array<U32>,
          r: Array<U32> & U32) -> Dp:
  (a, ai) = r
  row(256n, 0, ai, Dp{a, b, prev, cur[0] <- U32.inc(i)})

def dp.row(+i: U32, st: Dp) -> Dp:
  Dp{a, b, prev, cur} = st
  dp.f1(i, b, prev, cur, Array.get(U32, a, i))

# the DP: N rows
def dp(+n: Nat, +i: U32, st: Dp) -> Dp:
  match n:
    case 0n:
      st
    case 1n+q:
      dp(q, U32.inc(i), dp.row(i, st))

# the distance: prev[N] after the last row; the rest of the state
# drops
def dist.fin(r: Array<U32> & U32) -> U32:
  (prev, d) = r
  d

def dist(st: Dp) -> U32:
  Dp{a, b, prev, cur} = st
  dist.fin(Array.get(U32, prev, 256))

# one pair: seed from the hashed pair index, draw a and b, run the DP,
# mix the distance with the index
def pair(+p: U32) -> U32:
  +s = U32.mul(U32.inc(p), 2654435761)
  a = gen(256n, 0, s, [0 : U32*256n])
  b = gen(256n, 0, U32.mul(s, 340573321), [0 : U32*256n])
  prev = init(257n, 0, [0 : U32*512n])
  d = dist(dp(256n, 0, Dp{a, b, prev, [0 : U32*512n]}))
  U32.xor(U32.mul(d, 2654435761), U32.inc(p))

# batch tree over the pair index space
def batch(+d: Nat, +p: U32) -> U32:
  match d:
    case 0n:
      pair(p)
    case 1n+q:
      x y = batch(q, p) batch(q, U32.add(p, U32.shln(1, q)))
      U32.add(x, y)

def size.small() -> Nat:
  2n

def size.big() -> Nat:
  15n

# small: batch!(size.small(), 0) expect 2065873279; big
# batch!(size.big(), 0) expect 2229810577
def main() -> IO(Unit):
  IO.print(U32.show(batch!(size.big(), 0)))
