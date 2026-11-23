# lazy splits: one array shared by every lane through Array.fork, read at
# every leaf of a fork tree 14 deep, with a long side first so that second
# calls are split off holding a handle; the handles are joined back.
import Base

def rd(+x: U32, r: Array<U32> & U32) -> Array<U32> & U32:
  (a, +v) = r
  (a, (x * 31 + v : U32))

def q.join(l: Array<U32> & U32, r: Array<U32> & U32) -> Array<U32> & U32:
  (a, +x) = l
  (b, +y) = r
  (Array.join(U32, a, b), (x + y : U32))

@unsafe
def q.fork(+d: Nat, +x: U32, f: Array<U32> & Array<U32>) -> Array<U32> & U32:
  (a0, a1) = f
  l r = q(d, (x * 2 : U32), a0) q(d, (x * 2 + 1 : U32), a1)
  q.join(l, r)

@unsafe
def q(+d: Nat, +x: U32, a: Array<U32>) -> Array<U32> & U32:
  match d:
    case 0n:
      rd(x, a[(x % 4096 : U32)])
    case 1n+p:
      q.fork(p, x, Array.fork(U32, a))

def fin(r: Array<U32> & U32) -> U32:
  (a, +x) = r
  x

@unsafe
def main() -> U32:
  fin(q(14n, 1, Array.new(U32, 12n, 3)))

#|3892109312
