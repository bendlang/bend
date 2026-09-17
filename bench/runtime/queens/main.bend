import Base
# queens: parallel exhaustive N-queens backtracking search, ported 1-to-1 from
# Bend3's par_queens. Rows 0-3 are placed up front: batch forks the flat
# (c0,c1,c2,c3) prefix index space 0..2^d as a balanced tree; each leaf permutes
# its index by an odd multiplier, decodes its column quad (base-N digits), keeps
# it when legal under the solver's own bitmask rules, and runs the classic
# recursive bitmask backtracker over the remaining N-4 rows: peel the lowest
# candidate bit b = cand & (0 - cand), descend on the child row's candidate word
# full & ~(nc|nl|nr), then continue on the sibling set cand - b; the acc
# Stats{sols, nodes} counts one node per peel. smerge adds Stats pairwise up the
# fork tree. Bend3 hard-codes the prefix mask 131071 (d = 17); here the mask is
# 2^d - 1, threaded through batch, so small sizes shrink the prefix space the
# same way. a match scrutinizes only a parameter, so every decision bool is
# computed by the CALLER and passed as an argument: solve receives z =
# is_zero(cand) and e = is_eq(nc, full) with the peeled words, and each
# self-call site precomputes the next level's words; the prefix decode runs
# through the staged defs pfx.s1/s2/s3, each matching the bool its caller
# computed. the child's Stats result rides into the sibling call as the acc
# argument, so no call result is ever destructured in place.
# Checksum = (sols * 2654435761) ^ nodes.
# solve is ONE def and its recursion is structural: the shrinking
# candidate word is not a structure the checker can see, so a Nat fuel
# rides ahead of every self-call (match f, recurse on its pred g).
# Every nested self-call (child and sibling) drops the fuel by one, so
# fuel bounds the DEPTH of the call chain: at most one frame per peel
# plus one exit frame per row, under (n-3)*(n-2)+1 frames total. the
# initial call seeds n^2 (= nn2, already at hand), which exceeds that
# bound for every n >= 5, so the 0n arm is dead code and the count is
# exact.
#
# Sizes (d, n, limit): small (10, 5, 625) expect 774553824, big
# (17, 17, 11730) expect 2063750025. Small verified against a Bend3 C
# run on the cluster (mask 1023, run!(10, 5, 625)); big from the Bend3
# header.

type Stats is Data:
  Stat0{}
  Stats{sols: U32, nodes: U32}

def b2u(b: Bool) -> U32:
  match b:
    case False{}:
      0
    case True{}:
      1

def sel.go(x: U32, y: U32, z: Bool) -> U32:
  match z:
    case True{}:
      x
    case False{}:
      y

def sel(t: U32, x: U32, y: U32) -> U32:
  sel.go(x, y, U32.is_zero(t))

def sq(+x: U32) -> U32:
  U32.mul(x, x)

# the classic bitmask backtracker: descend on the child candidate
# word (the natural non-tail call), then tail-loop on the sibling set;
# the fuel f is the structure the descent rides, one unit per frame;
# z = is_zero(cand) and e = is_eq(nc, full) arrive precomputed
def solve(+f: Nat, z: Bool, e: Bool, +sib: U32, +nc: U32, +nl: U32, +nr: U32,
          +cols: U32, +ld: U32, +rd: U32, +full: U32, ret: Stats, sols: U32,
          nodes: U32) -> Stats:
  match f z e ret:
    case 0n z0 e0 Stat0{}:
      Stats{sols, nodes}
    case 0n z1 e2 Stats{s1, n1}:
      Stats{U32.add(sols, s1), U32.add(nodes, n1)}
    case 1n+g True{} e3 Stat0{}:
      Stats{sols, nodes}
    case 1n+g True{} e4 Stats{s1, n1}:
      Stats{U32.add(sols, s1), U32.add(nodes, n1)}
    case 1n+g False{} True{} Stat0{}:
      +b2 = U32.and(sib, U32.sub(0, sib))
      +n2 = U32.or(cols, b2)
      solve(g, U32.is_zero(sib), U32.is_eq(n2, full), U32.sub(sib, b2), n2,
        U32.shl(U32.or(ld, b2)), U32.shr(U32.or(rd, b2)),
        cols, ld, rd, full, Stat0{}, U32.inc(sols), U32.inc(nodes))
    case 1n+g False{} True{} Stats{s1, n1}:
      +b2 = U32.and(sib, U32.sub(0, sib))
      +n2 = U32.or(cols, b2)
      solve(g, U32.is_zero(sib), U32.is_eq(n2, full), U32.sub(sib, b2), n2,
        U32.shl(U32.or(ld, b2)), U32.shr(U32.or(rd, b2)),
        cols, ld, rd, full, Stat0{},
        U32.inc(U32.add(sols, s1)), U32.inc(U32.add(nodes, n1)))
    case 1n+g False{} False{} Stat0{}:
      +cc = U32.and(full, U32.not(U32.or(nc, U32.or(nl, nr))))
      +cb = U32.and(cc, U32.sub(0, cc))
      +cn = U32.or(nc, cb)
      +b2 = U32.and(sib, U32.sub(0, sib))
      +n2 = U32.or(cols, b2)
      solve(g, U32.is_zero(sib), U32.is_eq(n2, full), U32.sub(sib, b2), n2,
        U32.shl(U32.or(ld, b2)), U32.shr(U32.or(rd, b2)),
        cols, ld, rd, full,
        solve(g, U32.is_zero(cc), U32.is_eq(cn, full), U32.sub(cc, cb), cn,
          U32.shl(U32.or(nl, cb)), U32.shr(U32.or(nr, cb)),
          nc, nl, nr, full, Stat0{}, sols, U32.inc(nodes)), 0, 0)
    case 1n+g False{} False{} Stats{s1, n1}:
      +cc = U32.and(full, U32.not(U32.or(nc, U32.or(nl, nr))))
      +cb = U32.and(cc, U32.sub(0, cc))
      +cn = U32.or(nc, cb)
      +b2 = U32.and(sib, U32.sub(0, sib))
      +n2 = U32.or(cols, b2)
      solve(g, U32.is_zero(sib), U32.is_eq(n2, full), U32.sub(sib, b2), n2,
        U32.shl(U32.or(ld, b2)), U32.shr(U32.or(rd, b2)),
        cols, ld, rd, full,
        solve(g, U32.is_zero(cc), U32.is_eq(cn, full), U32.sub(cc, cb), cn,
          U32.shl(U32.or(nl, cb)), U32.shr(U32.or(nr, cb)),
          nc, nl, nr, full, Stat0{}, U32.add(sols, s1), U32.inc(U32.add(nodes, n1))), 0, 0)

# one 4-row prefix: permute the fork index (odd-multiplier bijection on
# the 2^d space), decode the column quad, filter illegal placements,
# solve the remaining rows; each stage matches the bool its caller
# computed
def pfx.s3(t: Bool, +nn2: U32, +full: U32, +b3: U32, +c3: U32, +l3: U32,
           +r3: U32) -> Stats:
  match t:
    case False{}:
      Stats{0, 0}
    case True{}:
      +c4 = U32.or(c3, b3)
      +l4 = U32.shl(U32.or(l3, b3))
      +r4 = U32.shr(U32.or(r3, b3))
      +cc = U32.and(full, U32.not(U32.or(c4, U32.or(l4, r4))))
      +cb = U32.and(cc, U32.sub(0, cc))
      +cn = U32.or(c4, cb)
      solve(U32.to_nat(nn2), U32.is_zero(cc), U32.is_eq(cn, full), U32.sub(cc, cb), cn,
        U32.shl(U32.or(l4, cb)), U32.shr(U32.or(r4, cb)),
        c4, l4, r4, full, Stat0{}, 0, 0)

def pfx.s2(t: Bool, +nn2: U32, +i: U32, +nn: U32, +full: U32, +b2: U32,
           +c2: U32, +l2: U32, +r2: U32) -> Stats:
  match t:
    case False{}:
      Stats{0, 0}
    case True{}:
      +b3 = U32.shln(1, U32.to_nat(U32.mod(i, nn)))
      +c3 = U32.or(c2, b2)
      +l3 = U32.shl(U32.or(l2, b2))
      +r3 = U32.shr(U32.or(r2, b2))
      pfx.s3(U32.is_eq(U32.and(b3, U32.or(c3, U32.or(l3, r3))), 0),
        nn2, full, b3, c3, l3, r3)

def pfx.s1(t: Bool, +nn2: U32, +i: U32, +nn: U32, +full: U32, +b0: U32,
           +b1: U32) -> Stats:
  match t:
    case False{}:
      Stats{0, 0}
    case True{}:
      +b2 = U32.shln(1, U32.to_nat(U32.mod(U32.div(i, nn), nn)))
      +c2 = U32.or(b0, b1)
      +l2 = U32.shl(U32.or(U32.shl(b0), b1))
      +r2 = U32.shr(U32.or(U32.shr(b0), b1))
      pfx.s2(U32.is_eq(U32.and(b2, U32.or(c2, U32.or(l2, r2))), 0),
        nn2, i, nn, full, b2, c2, l2, r2)

def pfx.d(+nn2: U32, +i: U32, +nn: U32, +full: U32) -> Stats:
  +b0 = U32.shln(1, U32.to_nat(U32.div(i, U32.mul(nn2, nn))))
  +b1 = U32.shln(1, U32.to_nat(U32.mod(U32.div(i, nn2), nn)))
  pfx.s1(U32.is_eq(U32.and(b1, U32.or(b0, U32.or(U32.shl(b0), U32.shr(b0)))), 0),
    nn2, i, nn, full, b0, b1)

def pfx.go2(t: Bool, +i: U32, +nn: U32, full: U32) -> Stats:
  match t:
    case False{}:
      Stats{0, 0}
    case True{}:
      pfx.d(U32.mul(nn, nn), i, nn, full)

def pfx.go(+i: U32, +nn: U32, full: U32, bound: U32) -> Stats:
  pfx.go2(U32.is_lt(i, bound), i, nn, full)

def pfx(j: U32, +m: U32, nn: U32, full: U32, bound: U32) -> Stats:
  pfx.go(U32.and(U32.mul(j, 2654435761), m), nn, full, bound)

def smerge(a: Stats, b: Stats) -> Stats:
  match a b:
    case Stats{s1, n1} Stats{s2, n2}:
      Stats{U32.add(s1, s2), U32.add(n1, n2)}
    case Stats{s1, n1} Stat0{}:
      Stats{s1, n1}
    case Stat0{} Stats{s2, n2}:
      Stats{s2, n2}
    case Stat0{} Stat0{}:
      Stat0{}

def batch(+d: Nat, +i: U32, +m: U32, +nn: U32, +full: U32,
          +bound: U32) -> Stats:
  match d:
    case 0n:
      pfx(i, m, nn, full, bound)
    case 1n+p:
      a b = batch(p, i, m, nn, full, bound) batch(p, U32.add(i, U32.shln(1, p)), m, nn, full, bound)
      smerge(a, b)

def run.fin(st: Stats) -> U32:
  match st:
    case Stat0{}:
      0
    case Stats{s, w}:
      U32.xor(U32.mul(s, 2654435761), w)

def run(+d: Nat, +n: U32, +lim: U32) -> U32:
  +nnnn = sq(sq(n))
  full = U32.sub(U32.shln(1, U32.to_nat(n)), 1)
  # bound = min-like clamp: lim when lim < n^4, else n^4
  run.fin(batch(d, 0, U32.sub(U32.shln(1, d), 1), n, full,
    sel(b2u(U32.is_lt(lim, nnnn)), nnnn, lim)))

def size() -> U32:
  17

def limit() -> U32:
  11730

# small: run!(10n, 5, 625) expect 774553824; big expect 2063750025
def main() -> IO(Unit):
  IO.print(U32.show(run!(17n, size(), limit())))
