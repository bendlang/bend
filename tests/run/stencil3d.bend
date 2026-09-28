# a 3D 7-point periodic stencil (origin: yuu.ka's stencil bench) in the
# ONE GPGPU pattern: a 16^3 grid of u32 (cell i = xorshift13/17/5(i) &
# 255), 3 passes, each cell the sum of itself and its six wrapped
# neighbours >> 3, double-buffered. main allocates two grid blocks once.
# fill forks one grid down 4 levels (each fork is two O(1) handles to
# the same block) and leaf i stores its 256 cells with Array.set. Each
# pass is one launch that forks the input and the output grid the same
# way: leaf i loops its chunk with 7 Array.get reads through its input
# handle and one Array.set through its output handle, the joins give
# the blocks back, and the grids swap. Nothing is split or rebuilt: no
# match on a grid, no ANode. The checksum folds acc = (acc * 2654435761)
# ^ v in index order through an Array.get loop on the host, after the !
# region. Value from an independent plain-Python reference (a flat list,
# the same prng, passes and fold), and equal to the split-in-place and
# copying shapes that came before it.
import Base

def sb() -> Nat:
  4n

def sb2() -> Nat:
  8n

def msk() -> U32:
  15

def dep() -> Nat:
  12n

def len() -> Nat:
  4096n

def frk() -> Nat:
  4n

def cnt() -> Nat:
  256n

def cnt32() -> U32:
  256

def pas() -> Nat:
  3n

def prng(+x: U32) -> U32:
  +a = U32.xor(x, U32.shln(x, 13n))
  +b = U32.xor(a, U32.shrn(a, 17n))
  U32.xor(b, U32.shln(b, 5n))

# fill

def fillk(+n: Nat, +i: U32, o: Array<U32>) -> Array<U32>:
  match n:
    case 0n:
      o
    case 1n+q:
      fillk(q, U32.inc(i), Array.set(U32, o, i, U32.and(prng(i), 255)))

@unsafe
def fill(+d: Nat, +i: U32, +a: Array<U32>) -> Array<U32>:
  match d:
    case 0n:
      fillk(cnt(), U32.mul(i, cnt32()), a)
    case 1n+p:
      l r = fill(p, U32.shln(i, 1n), a) fill(p, U32.or(U32.shln(i, 1n), 1), a)
      Array.join(U32, l, r)

# kernel

def idx(x: U32, y: U32, z: U32) -> U32:
  U32.or(U32.shln(U32.and(z, msk()), sb2()),
    U32.or(U32.shln(U32.and(y, msk()), sb()), U32.and(x, msk())))

def acc(s: U32, r: Array<U32> & U32) -> Array<U32> & U32:
  (v, x) = r
  (v, U32.add(s, x))

def rd(j: U32, r: Array<U32> & U32) -> Array<U32> & U32:
  (v, s) = r
  acc(s, Array.get(U32, v, j))

def cell(+i: U32, v: Array<U32>) -> Array<U32> & U32:
  +x = U32.and(i, msk())
  +y = U32.and(U32.shrn(i, sb()), msk())
  +z = U32.shrn(i, sb2())
  r = rd(idx(x, y, z), (v, 0))
  r = rd(idx(U32.sub(x, 1), y, z), r)
  r = rd(idx(U32.inc(x), y, z), r)
  r = rd(idx(x, U32.sub(y, 1), z), r)
  r = rd(idx(x, U32.inc(y), z), r)
  r = rd(idx(x, y, U32.sub(z, 1)), r)
  rd(idx(x, y, U32.inc(z)), r)

def put(i: U32, out: Array<U32>, r: Array<U32> & U32) -> Array<U32> & Array<U32>:
  (v, s) = r
  (v, Array.set(U32, out, i, U32.shrn(s, 3n)))

def stepc(+i: U32, p: Array<U32> & Array<U32>) -> Array<U32> & Array<U32>:
  (v, out) = p
  put(i, out, cell(i, v))

def kloop(+n: Nat, +i: U32, p: Array<U32> & Array<U32>) -> Array<U32> & Array<U32>:
  match n:
    case 0n:
      p
    case 1n+q:
      kloop(q, U32.inc(i), stepc(i, p))

@unsafe
def kernel(+n: Nat, +i: U32, inp: Array<U32>, out: Array<U32>) -> Array<U32> & Array<U32>:
  kloop(n, i, (inp, out))

# launch

def join2(l: Array<U32> & Array<U32>, r: Array<U32> & Array<U32>) -> Array<U32> & Array<U32>:
  (la, lb) = l
  (ra, rb) = r
  (Array.join(U32, la, ra), Array.join(U32, lb, rb))

@unsafe
def launch(+d: Nat, +i: U32, +inp: Array<U32>, +out: Array<U32>) -> Array<U32> & Array<U32>:
  match d:
    case 0n:
      kernel(cnt(), U32.mul(i, cnt32()), inp, out)
    case 1n+p:
      l r = launch(p, U32.shln(i, 1n), inp, out) launch(p, U32.or(U32.shln(i, 1n), 1), inp, out)
      join2(l, r)

# passes

def swap2(p: Array<U32> & Array<U32>) -> Array<U32> & Array<U32>:
  (v, out) = p
  (out, v)

def pass(p: Array<U32> & Array<U32>) -> Array<U32> & Array<U32>:
  (v, o) = p
  swap2(launch(frk(), 0, v, o))

def sweep(+n: Nat, p: Array<U32> & Array<U32>) -> Array<U32> & Array<U32>:
  match n:
    case 0n:
      p
    case 1n+r:
      sweep(r, pass(p))

def run(a: Array<U32>, b: Array<U32>) -> Array<U32> & Array<U32>:
  sweep(pas(), (fill(frk(), 0, a), b))

# host

def mix(s: U32, r: Array<U32> & U32) -> Array<U32> & U32:
  (a, x) = r
  (a, U32.xor(U32.mul(s, 2654435761), x))

def ckc(+i: U32, r: Array<U32> & U32) -> Array<U32> & U32:
  (a, s) = r
  mix(s, Array.get(U32, a, i))

def ckl(+n: Nat, +i: U32, r: Array<U32> & U32) -> Array<U32> & U32:
  match n:
    case 0n:
      r
    case 1n+q:
      ckl(q, U32.inc(i), ckc(i, r))

def ck.fin(r: Array<U32> & U32) -> U32:
  (a, s) = r
  s

def ck(p: Array<U32> & Array<U32>) -> U32:
  (out, old) = p
  ck.fin(ckl(len(), 0, (out, 0)))

def main() -> IO(Unit):
  IO.print(U32.show(ck(run!(Array.new(U32, dep(), 0), Array.new(U32, dep(), 0)))))

#|2639387968
