# A generic def (pair.go) copied for lambdas whose parameters are U32s
# read more than once, under records of arrays and through a recursion:
# delaunay-animation's LZW coder in its closure spelling. Each copy's types
# must be its own: a type held in a cell names its def's levels, and a
# U32 read as a box does not build. Also a copy whose call fills k's erased
# type arguments, and lambdas nested three deep.
import Base

@unsafe
def pair.go(-A: Type, -B: Type, -R: Type, p: A & B, k: A -> B -> R) -> R:
  (a, b) = p
  k(a, b)

def depth(+n: U32) -> Nat:
  1n+U32.log2((n - 1 : U32))

# LZW.codeStream 256: the code table's lists of (idx, code) as linked lists in
# arrays (hd[code] the newest entry, 0 for none; entry c, made when code c was
# made, is ix[c] with next nx[c]); the codes to out
type LZ is Type:
  LZ{idx: Array<U32>, hd: Array<U32>, ix: Array<U32>, nx: Array<U32>, out: Array<U32>}

def lz.clear(k: Nat, +i: U32, hd: Array<U32>) -> Array<U32>:
  match k:
    case 0n:
      hd
    case 1n+q:
      lz.clear(q, (i + 1 : U32), hd[i] <- 0)

@unsafe
def lz.find(+e: U32, +x: U32, s: LZ) -> LZ & U32:
  lz.find.go(U32.is_eq(e, 0), e, x, s)

@unsafe
def lz.find.go(z: Bool, +e: U32, +x: U32, s: LZ) -> LZ & U32:
  match z:
    case True{}:
      (s, 0)
    case False{}:
      LZ{idx, hd, ix, nx, out} = s
      pair.go(Array<U32>, U32, LZ & U32, ix[e], ix2 => +v => lz.find.n(U32.is_eq(v, x), e, x, LZ{idx, hd, ix2, nx, out}))

@unsafe
def lz.find.n(hit: Bool, +e: U32, +x: U32, s: LZ) -> LZ & U32:
  match hit:
    case True{}:
      (s, e)
    case False{}:
      LZ{idx, hd, ix, nx, out} = s
      pair.go(Array<U32>, U32, LZ & U32, nx[e], nx2 => +n2 => lz.find(n2, x, LZ{idx, hd, ix, nx2, out}))

# no entry (cur, x): insert it, or clear the table when it is full
@unsafe
def lz.miss(full: Bool, q: Nat, +i: U32, +cur: U32, +x: U32, +nc: U32, +o: U32, s: LZ) -> LZ & U32:
  match full:
    case True{}:
      LZ{idx, hd, ix, nx, out} = s
      lz.loop(q, (i + 1 : U32), x, 258, (o + 2 : U32), LZ{idx, lz.clear(4096n, 0, hd), ix, nx, (out[o] <- cur)[(o + 1 : U32)] <- 256})
    case False{}:
      LZ{idx, hd, ix, nx, out} = s
      pair.go(Array<U32>, U32, LZ & U32, hd[cur], hd2 => +old =>
        lz.loop(q, (i + 1 : U32), x, (nc + 1 : U32), (o + 1 : U32), LZ{idx, hd2[cur] <- nc, ix[nc] <- x, nx[nc] <- old, out[o] <- cur}))

@unsafe
def lz.hit.go(miss: Bool, q: Nat, +i: U32, +cur: U32, +x: U32, +e: U32, +nc: U32, +o: U32, s: LZ) -> LZ & U32:
  match miss:
    case True{}:
      lz.miss(U32.is_eq(nc, 4095), q, i, cur, x, nc, o, s)
    case False{}:
      lz.loop(q, (i + 1 : U32), e, nc, o, s)

# from index i, k left; cur the code of the buffer, nc the next code, o codes out
@unsafe
def lz.loop(k: Nat, +i: U32, +cur: U32, +nc: U32, +o: U32, s: LZ) -> LZ & U32:
  match k:
    case 0n:
      LZ{idx, hd, ix, nx, out} = s
      (LZ{idx, hd, ix, nx, (out[o] <- cur)[(o + 1 : U32)] <- 257}, (o + 2 : U32))
    case 1n+q:
      LZ{idx, hd, ix, nx, out} = s
      pair.go(Array<U32>, U32, LZ & U32, idx[i], idx2 => +x => pair.go(Array<U32>, U32, LZ & U32, hd[cur], hd2 => +e =>
        pair.go(LZ, U32, LZ & U32, lz.find(e, x, LZ{idx2, hd2, ix, nx, out}), s2 => +e2 => lz.hit.go(U32.is_eq(e2, 0), q, i, cur, x, e2, nc, o, s2))))

# the codes of pp color indices: the codes array and their number
@unsafe
def lz.stream(+pp: U32, idx: Array<U32>) -> Array<U32> & U32:
  pair.go(Array<U32>, U32, Array<U32> & U32, idx[0], i2 => +c0 => lz.out(lz.loop(U32.to_nat((pp - 1 : U32)), 1, c0, 258, 1, LZ{i2, Array.new(U32, 12n, 0), Array.new(U32, 12n, 0), Array.new(U32, 12n, 0), Array.set(U32, Array.new(U32, depth((pp + pp / 1000 + 16 : U32)), 0), 0, 256)})))

def lz.out(r: LZ & U32) -> Array<U32> & U32:
  (s, +n) = r
  LZ{idx, hd, ix, nx, out} = s
  (out, n)


def fill(k: Nat, +i: U32, a: Array<U32>) -> Array<U32>:
  match k:
    case 0n:
      a
    case 1n+p:
      fill(p, (i + 1 : U32), a[i] <- ((i * 7 + i / 3) % 256 : U32))

def sum(k: Nat, +i: U32, +acc: U32, a: Array<U32>) -> U32:
  match k:
    case 0n:
      acc
    case 1n+p:
      pair.go(Array<U32>, U32, U32, a[i], a2 => +v => sum(p, (i + 1 : U32), (acc * 31 + v : U32), a2))

def fin(r: Array<U32> & U32) -> U32:
  (a, +n) = r
  (sum(100n, 0, 0, a) + n : U32)

def main() -> U32:
  fin(lz.stream(5000, fill(5000n, 0, Array.new(U32, 13n, 0))))

#|191337777
