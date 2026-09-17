import Base
# kmeans: k-means clustering with random restarts, ported 1-to-1 from
# Bend3's par_kmeans. 64 independent restarts fork as a batch tree; each
# runs 20 Lloyd rounds over 2^SIZE prng points (10-bit 2D coords,
# regenerated from their index hash) and K = 8 clusters. A round folds
# the point tree in 64-point leaf chunks: a chunk picks each point's
# nearest centroid (8 squared distances, branchless argmin) and
# accumulates 8x{sx,sy,n} in 24 scalar registers -- pure uniform
# arithmetic -- materializing one complete stats tree per chunk; szip
# merges the trees pairwise up the forked reduction, and the round
# extracts the 8 new centroids (sum/count, empty keeps the old one).
# Checksum sums the restarts' final-centroid mixes. Round, chunk and
# depth counters are Nats (no U32 match in Bend4).
#
# NO TUNING: this file is the elegant spelling. A flat-24-scalar-record
# rewrite of the stats merge measured GPU 0.65 -> 0.17s and was
# reverted: it tuned the bench, not the compiler. The gap is the
# seq-machine frame class on the boxed merge -- a COMPILER TODO, not a
# bench edit.
#
# Sizes (SIZE): small (7n) expect 4219097976 (verified against a
# Bend3 C run on the cluster), big (19n) expect 1616398086 (from the
# Bend3 header, verified on the cluster in seq, par and metal modes).

type St is Data:
  Sl{sx: U32, sy: U32, n: U32}
  Sn{l: St, r: St}

def b2u(b: Bool) -> U32:
  match b:
    case False{}:
      0
    case True{}:
      1

def prng(+x: U32) -> U32:
  +b = U32.xor(x, U32.shln(x, 13n))
  +d = U32.xor(b, U32.shrn(b, 17n))
  U32.xor(d, U32.shln(d, 5n))

def sel.go(x: U32, y: U32, z: Bool) -> U32:
  match z:
    case True{}:
      x
    case False{}:
      y

def sel(t: U32, x: U32, y: U32) -> U32:
  sel.go(x, y, U32.is_zero(t))

def min2(+a: U32, +b: U32) -> U32:
  sel(b2u(U32.is_lt(a, b)), b, a)

# squared distance from (x, y) to packed centroid c, tagged with slot k:
# d ranges to 2*1023^2 < 2^21, so d<<3|k fits comfortably
def dst(+x: U32, +y: U32, +c: U32, k: U32) -> U32:
  +dx = sel(b2u(U32.is_lt(x, U32.and(c, 65535))), U32.sub(x, U32.and(c, 65535)), U32.sub(U32.and(c, 65535), x))
  +dy = sel(b2u(U32.is_lt(y, U32.shrn(c, 16n))), U32.sub(y, U32.shrn(c, 16n)), U32.sub(U32.shrn(c, 16n), y))
  U32.or(U32.shln(U32.add(U32.mul(dx, dx), U32.mul(dy, dy)), 3n), k)

def szip(a: St, b: St) -> St:
  match a b:
    case Sl{a, b, c} Sl{d, e, f}:
      Sl{U32.add(a, d), U32.add(b, e), U32.add(c, f)}
    case Sl{a, b, c} Sn{l, r}:
      Sl{a, b, c}
    case Sn{l, r} Sl{a, b, c}:
      Sn{l, r}
    case Sn{a, b} Sn{c, d}:
      l r = szip(a, c) szip(b, d)
      Sn{l, r}

# combiner: a leaf chunk folds 64 points into 24 scalar accumulators
# (8 clusters x sx/sy/n, branchless masked adds -- pure register math),
# then materializes one stats tree per chunk for the forked reduction
def chunk(+j: Nat, +i: U32, +c0: U32, +c1: U32, +c2: U32, +c3: U32, +c4: U32,
          +c5: U32, +c6: U32, +c7: U32, s0x: U32, s0y: U32, s0n: U32, s1x: U32,
          s1y: U32, s1n: U32, s2x: U32, s2y: U32, s2n: U32, s3x: U32, s3y: U32,
          s3n: U32, s4x: U32, s4y: U32, s4n: U32, s5x: U32, s5y: U32, s5n: U32,
          s6x: U32, s6y: U32, s6n: U32, s7x: U32, s7y: U32, s7n: U32) -> St:
  match j:
    case 0n:
      Sn{Sn{Sn{Sl{s0x, s0y, s0n}, Sl{s1x, s1y, s1n}}, Sn{Sl{s2x, s2y, s2n}, Sl{s3x, s3y, s3n}}},
         Sn{Sn{Sl{s4x, s4y, s4n}, Sl{s5x, s5y, s5n}}, Sn{Sl{s6x, s6y, s6n}, Sl{s7x, s7y, s7n}}}}
    case 1n+p:
      +hh = prng(U32.mul(U32.inc(U32.add(i, U32.from_nat(p))), 2654435761))
      +xx = U32.and(hh, 1023)
      +yy = U32.and(U32.shrn(hh, 16n), 1023)
      +bk = U32.and(min2(min2(min2(dst(xx, yy, c0, 0), dst(xx, yy, c1, 1)),
                              min2(dst(xx, yy, c2, 2), dst(xx, yy, c3, 3))),
                         min2(min2(dst(xx, yy, c4, 4), dst(xx, yy, c5, 5)),
                              min2(dst(xx, yy, c6, 6), dst(xx, yy, c7, 7)))), 7)
      +m0 = b2u(U32.is_eq(bk, 0))
      +m1 = b2u(U32.is_eq(bk, 1))
      +m2 = b2u(U32.is_eq(bk, 2))
      +m3 = b2u(U32.is_eq(bk, 3))
      +m4 = b2u(U32.is_eq(bk, 4))
      +m5 = b2u(U32.is_eq(bk, 5))
      +m6 = b2u(U32.is_eq(bk, 6))
      +m7 = b2u(U32.is_eq(bk, 7))
      chunk(p, i, c0, c1, c2, c3, c4, c5, c6, c7,
            U32.add(s0x, U32.mul(m0, xx)), U32.add(s0y, U32.mul(m0, yy)), U32.add(s0n, m0),
            U32.add(s1x, U32.mul(m1, xx)), U32.add(s1y, U32.mul(m1, yy)), U32.add(s1n, m1),
            U32.add(s2x, U32.mul(m2, xx)), U32.add(s2y, U32.mul(m2, yy)), U32.add(s2n, m2),
            U32.add(s3x, U32.mul(m3, xx)), U32.add(s3y, U32.mul(m3, yy)), U32.add(s3n, m3),
            U32.add(s4x, U32.mul(m4, xx)), U32.add(s4y, U32.mul(m4, yy)), U32.add(s4n, m4),
            U32.add(s5x, U32.mul(m5, xx)), U32.add(s5y, U32.mul(m5, yy)), U32.add(s5n, m5),
            U32.add(s6x, U32.mul(m6, xx)), U32.add(s6y, U32.mul(m6, yy)), U32.add(s6n, m6),
            U32.add(s7x, U32.mul(m7, xx)), U32.add(s7y, U32.mul(m7, yy)), U32.add(s7n, m7))

def pfold(+d: Nat, +i: U32, +c0: U32, +c1: U32, +c2: U32, +c3: U32, +c4: U32,
          +c5: U32, +c6: U32, +c7: U32) -> St:
  match d:
    case 0n:
      chunk(64n, i, c0, c1, c2, c3, c4, c5, c6, c7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    case 1n+p:
      a b = pfold(p, i, c0, c1, c2, c3, c4, c5, c6, c7) pfold(p, U32.add(i, U32.shln(64, p)), c0, c1, c2, c3, c4, c5, c6, c7)
      szip(a, b)

# new centroid from a stats leaf; an empty cluster keeps the old one
# (the divisor is forced to 1 when empty: sel picks eagerly)
def cnew(s: St, old: U32) -> U32:
  match s:
    case Sl{sx, sy, +n}:
      +mm = sel(b2u(U32.is_zero(n)), n, 1)
      sel(b2u(U32.is_zero(n)), U32.or(U32.div(sx, mm), U32.shln(U32.div(sy, mm), 16n)), old)
    case Sn{l, r}:
      old

type Cs is Data:
  Cs{c0: U32, c1: U32, c2: U32, c3: U32, c4: U32, c5: U32, c6: U32, c7: U32}

# extract the 8 new centroids from the depth-3 stats tree (the
# catch-all row is an unreachable filler: a chunk always materializes
# the full Sn^3 shape and szip preserves it)
def step.fin(c0: U32, c1: U32, c2: U32, c3: U32, c4: U32, c5: U32, c6: U32,
             c7: U32, t: St) -> Cs:
  match t:
    case Sn{Sn{Sn{q0, q1}, Sn{q2, q3}}, Sn{Sn{q4, q5}, Sn{q6, q7}}}:
      Cs{cnew(q0, c0), cnew(q1, c1), cnew(q2, c2), cnew(q3, c3),
         cnew(q4, c4), cnew(q5, c5), cnew(q6, c6), cnew(q7, c7)}
    case t2:
      Cs{c0, c1, c2, c3, c4, c5, c6, c7}

def step(d: Nat, +c0: U32, +c1: U32, +c2: U32, +c3: U32, +c4: U32, +c5: U32,
         +c6: U32, +c7: U32) -> Cs:
  step.fin(c0, c1, c2, c3, c4, c5, c6, c7,
    pfold(Nat.sub(d, 6n), 0, c0, c1, c2, c3, c4, c5, c6, c7))

def loop(r: Nat, +d: Nat, cs: Cs) -> U32:
  match r cs:
    case 0n Cs{c0, c1, c2, c3, c4, c5, c6, c7}:
      m1 = U32.add(U32.mul(c0, 2654435761), c1)
      m2 = U32.add(U32.mul(m1, 2654435761), c2)
      m3 = U32.add(U32.mul(m2, 2654435761), c3)
      m4 = U32.add(U32.mul(m3, 2654435761), c4)
      m5 = U32.add(U32.mul(m4, 2654435761), c5)
      m6 = U32.add(U32.mul(m5, 2654435761), c6)
      U32.add(U32.mul(m6, 2654435761), c7)
    case 1n+p Cs{c0, c1, c2, c3, c4, c5, c6, c7}:
      loop(p, d, step(d, c0, c1, c2, c3, c4, c5, c6, c7))

def cini(k: U32) -> U32:
  +hh = prng(U32.add(12345, k))
  U32.or(U32.and(hh, 1023), U32.shln(U32.and(U32.shrn(hh, 16n), 1023), 16n))

# one restart: 20 Lloyd rounds from this restart's random centroids
def rst(r: U32, d: Nat) -> U32:
  +rr = U32.mul(r, 8)
  loop(20n, d, Cs{cini(U32.inc(rr)), cini(U32.add(rr, 2)), cini(U32.add(rr, 3)), cini(U32.add(rr, 4)), cini(U32.add(rr, 5)), cini(U32.add(rr, 6)), cini(U32.add(rr, 7)), cini(U32.add(rr, 8))})

# 64 independent restarts fork as a balanced tree (kmeans++ style
# restarts keep the machine wide across the whole run)
def rbatch(+b: Nat, +r: U32, +d: Nat) -> U32:
  match b:
    case 0n:
      rst(r, d)
    case 1n+p:
      x y = rbatch(p, r, d) rbatch(p, U32.add(r, U32.shln(1, p)), d)
      U32.add(x, y)

def size() -> Nat:
  19n

# small: size 7n expect 4219097976; big (19n) expect 1616398086
def main() -> IO(Unit):
  IO.print(U32.show(rbatch!(6n, 0, size())))
