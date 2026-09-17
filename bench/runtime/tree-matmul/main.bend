import Base
# Matmul: recursive block matrix multiply over quad-trees, with a
# Freivalds verification pass, ported 1-to-1 from Bend3's
# par_tree_mat_mul (Bend3's own(x) boxes drop -- Bend4 spells the
# shares as + binders).
# 2^blog slots fork as a balanced batch tree; each live leaf runs one
# round: generate two pseudo-random 2^size x 2^size matrices as
# depth-size quad-trees, multiply them block-recursively (each node
# spawns its whole 8-product burst as ONE 8-way fork), then verify
# C = A*B by Freivalds' check: fold |C*r - A*(B*r)| over a random
# vector r (exact in wrapping u32, so the or-fold is 0 iff the product
# is right). Round checksums mix the matrix fold with the verification
# bit and sum up the fork tree. Depth counters
# are Nats (no U32 match in Bend4). This bench clones heap values: mul
# and round share whole Mat/Vec trees through + binders.
#
# Sizes (size, blog, nchain): small (3, 2, 3) expect 4292995302
# (verified against a Bend3 C run on the cluster), big (7, 9, 384)
# expect 3797651056 (from the Bend3 header).

type Mat is Data:
  Lf{v: U32}
  Qd{a: Mat, b: Mat, c: Mat, d: Mat}

type Vec is Data:
  Vl{v: U32}
  Vn{l: Vec, r: Vec}

def b2u(b: Bool) -> U32:
  match b:
    case False{}:
      0
    case True{}:
      1

def gen(+d: Nat, +s: U32) -> Mat:
  match d:
    case 0n:
      Lf{U32.mod(s, 100)}
    case 1n+p:
      a b c e = gen(p, U32.inc(U32.mul(s, 1664525))) gen(p, U32.add(U32.mul(s, 214013), 3)) gen(p, U32.add(U32.mul(s, 16843009), 5)) gen(p, U32.add(U32.mul(s, 48271), 7))
      Qd{a, b, c, e}

def vgen(+d: Nat, +s: U32) -> Vec:
  match d:
    case 0n:
      Vl{U32.inc(U32.mod(U32.mul(s, 2654435761), 100))}
    case 1n+p:
      l r = vgen(p, U32.inc(U32.mul(s, 1664525))) vgen(p, U32.add(U32.mul(s, 214013), 3))
      Vn{l, r}

def add(a: Mat, b: Mat) -> Mat:
  match a b:
    case Lf{x} Lf{y}:
      Lf{U32.add(x, y)}
    case Lf{x} Qd{b0, b1, b2, b3}:
      Lf{0}
    case Qd{a0, a1, a2, a3} Lf{y}:
      Lf{0}
    case Qd{a0, a1, a2, a3} Qd{b0, b1, b2, b3}:
      r0 r1 r2 r3 = add(a0, b0) add(a1, b1) add(a2, b2) add(a3, b3)
      Qd{r0, r1, r2, r3}

# join of one mul burst: C_ij = P_ij + Q_ij, all four quadrant sums
# in one balanced fork
def add4(p0: Mat, q0: Mat, p1: Mat, q1: Mat, p2: Mat, q2: Mat,
         p3: Mat, q3: Mat) -> Mat:
  c0 c1 c2 c3 = add(p0, q0) add(p1, q1) add(p2, q2) add(p3, q3)
  Qd{c0, c1, c2, c3}

# each node spawns its whole 8-product burst as ONE 8-way fork,
# then joins through add4's single add burst
def mul(+a: Mat, +b: Mat) -> Mat:
  match a b:
    case Lf{x} Lf{y}:
      Lf{U32.mul(x, y)}
    case Lf{x} Qd{b0, b1, b2, b3}:
      Lf{0}
    case Qd{a0, a1, a2, a3} Lf{y}:
      Lf{0}
    case Qd{a0, a1, a2, a3} Qd{b0, b1, b2, b3}:
      p0 q0 p1 q1 p2 q2 p3 q3 = mul(a0, b0) mul(a1, b2) mul(a0, b1) mul(a1, b3) mul(a2, b0) mul(a3, b2) mul(a2, b1) mul(a3, b3)
      add4(p0, q0, p1, q1, p2, q2, p3, q3)

def vadd(x: Vec, y: Vec) -> Vec:
  match x y:
    case Vl{a} Vl{b}:
      Vl{U32.add(a, b)}
    case Vl{a} Vn{c, d}:
      Vl{0}
    case Vn{a, b} Vl{c}:
      Vl{0}
    case Vn{a, b} Vn{c, d}:
      l r = vadd(a, c) vadd(b, d)
      Vn{l, r}

# join of one mvm burst: both half-sums in one fork
def vadd2(t0: Vec, t1: Vec, t2: Vec, t3: Vec) -> Vec:
  top bot = vadd(t0, t1) vadd(t2, t3)
  Vn{top, bot}

# [[a,b],[c,d]] * (l,h) = (a*l + b*h, c*l + d*h)
def mvm(m: Mat, +v: Vec) -> Vec:
  match m v:
    case Lf{x} Vl{y}:
      Vl{U32.mul(x, y)}
    case Lf{x} Vn{l, h}:
      Vl{0}
    case Qd{a, b, c, d} Vl{y}:
      Vl{0}
    case Qd{a, b, c, d} Vn{l, h}:
      t0 t1 t2 t3 = mvm(a, l) mvm(b, h) mvm(c, l) mvm(d, h)
      vadd2(t0, t1, t2, t3)

def cksum(m: Mat) -> U32:
  match m:
    case Lf{x}:
      x
    case Qd{a, b, c, d}:
      p q r s = cksum(a) cksum(b) cksum(c) cksum(d)
      U32.add(U32.add(U32.add(p, q), r), s)

# or-fold of elementwise xor: 0 iff the vectors are identical
def vdif(x: Vec, y: Vec) -> U32:
  match x y:
    case Vl{a} Vl{b}:
      U32.xor(a, b)
    case Vl{a} Vn{c, d}:
      1
    case Vn{a, b} Vl{c}:
      1
    case Vn{a, b} Vn{c, d}:
      l r = vdif(a, c) vdif(b, d)
      U32.or(l, r)

# one round: generate A, B, r; C = A*B; Freivalds-verify C*r == A*(B*r)
def round(+d: Nat, +s: U32) -> U32:
  +a +b = gen(d, U32.inc(s)) gen(d, U32.add(s, 2))
  +r = vgen(d, U32.add(s, 3))
  +c = mul(a, b)
  k = cksum(c)
  t1 = mvm(c, r)
  t2 = mvm(a, mvm(b, r))
  U32.add(U32.xor(k, U32.mul(s, 2654435761)), b2u(U32.is_zero(vdif(t1, t2))))

def batch.leaf.go(t: Bool, d: Nat, pp: U32) -> U32:
  match t:
    case False{}:
      0
    case True{}:
      round(d, U32.mul(pp, 2654435761))

def batch.leaf(+pp: U32, n: U32, d: Nat) -> U32:
  batch.leaf.go(U32.is_lt(pp, n), d, pp)

# batch tree over the round index space: leaf i runs one round when
# p < nchain, p = the leaf's odd-multiplier permuted index (seed =
# hashed p, so the live chain set -- and the checksum -- is the same
# for any spread)
def batch(+bg: Nat, +i: U32, +n: U32, +m: U32, +d: Nat) -> U32:
  match bg:
    case 0n:
      batch.leaf(U32.and(U32.mul(i, 2654435761), m), n, d)
    case 1n+p:
      x y = batch(p, i, n, m, d) batch(p, U32.add(i, U32.shln(1, p)), n, m, d)
      U32.add(x, y)

def size() -> Nat:
  7n

def blog() -> Nat:
  9n

def nchain() -> U32:
  384

# small: size 3n blog 2n nchain 3 expect 4292995302; big expect 3797651056
def main() -> IO(Unit):
  mm = U32.sub(U32.shln(1, blog()), 1)
  IO.print(U32.show(batch!(blog(), 0, nchain(), mm, size())))
