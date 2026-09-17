# in-place bubble sort of an F32 array: word elements read/compare/swap
# through the linear array, digest exact in f32
# ported from bend3: f32 literals are rebuilt exactly via F32.div of
# small integers; a read is a double Array.swap (bend's generic array
# op); a > b is spelled F32.is_lt(b, a); no interpreter lane (Base's
# F32 axioms are stuck there)
import Base

law fl:
  for n: U32
  for d: U32
  F32

def fl(n, d):
  F32.div(U32.to_f32(n), U32.to_f32(d))

law rd:
  for  m: Array<F32>
  for +j: U32
  Array<F32> & F32

law rd.fin:
  for +v: F32
  for  w: Array<F32> & F32
  Array<F32> & F32

def rd.fin(v, w):
  (m3, z) = w
  (m3, v)

law rd.go:
  for +j: U32
  for  w: Array<F32> & F32
  Array<F32> & F32

def rd.go(j, w):
  (m2, v0) = w
  +v = {v0 : F32}
  rd.fin(v, Array.swap(F32, m2, j, v))

def rd(m, j):
  rd.go(j, Array.swap(F32, m, j, fl(0, 1)))

law swp.d:
  for +j: U32
  for  a: F32
  for  b: F32
  for  m: Array<F32>
  Array<F32>

law swp.d.fin:
  for w: Array<F32> & F32
  Array<F32>

def swp.d.fin(w):
  (m3, o2) = w
  m3

law swp.d.go:
  for +j: U32
  for  a: F32
  for  w: Array<F32> & F32
  Array<F32>

def swp.d.go(j, a, w):
  (m2, o1) = w
  swp.d.fin(Array.swap(F32, m2, U32.add(j, 1), a))

def swp.d(j, a, b, m):
  swp.d.go(j, a, Array.swap(F32, m, j, b))

law swp.c:
  for +j: U32
  for +a: F32
  for +b: F32
  for  m: Array<F32>
  Array<F32>

law swp.c.if:
  for +j: U32
  for +a: F32
  for +b: F32
  for  m: Array<F32>
  for  z: Bool
  Array<F32>

def swp.c.if(j, a, b, m, z):
  match z:
    case False{}:
      m
    case True{}:
      swp.d(j, a, b, m)

def swp.c(j, a, b, m):
  swp.c.if(j, a, b, m, F32.is_lt(b, a))

law swp.b:
  for +j: U32
  for  a: F32
  for  m: Array<F32>
  Array<F32>

law swp.b.go:
  for +j: U32
  for  a: F32
  for  w: Array<F32> & F32
  Array<F32>

def swp.b.go(j, a, w):
  (m2, b) = w
  swp.c(j, a, b, m2)

def swp.b(j, a, m):
  swp.b.go(j, a, rd(m, U32.add(j, 1)))

law swp:
  for +j: U32
  for  m: Array<F32>
  Array<F32>

law swp.go:
  for +j: U32
  for  w: Array<F32> & F32
  Array<F32>

def swp.go(j, w):
  (m1, a) = w
  swp.b(j, a, m1)

def swp(j, m):
  swp.go(j, rd(m, j))

law pass:
  for +j: Nat
  for  m: Array<F32>
  Array<F32>

def pass(j, m):
  match j:
    case 0n:
      m
    case 1n+p:
      pass(p, swp(U32.sub(3, U32.add(U32.from_nat(p), 1)), m))

law rounds:
  for r: Nat
  for m: Array<F32>
  Array<F32>

def rounds(r, m):
  match r:
    case 0n:
      m
    case 1n+p:
      rounds(p, pass(3n, m))

law build:
  Array<F32>

def build():
  {ANode{ANode{ALeaf{fl(7, 2)}, ALeaf{fl(5, 2)}}, ANode{ALeaf{fl(5, 4)}, ALeaf{fl(1, 2)}}} : Array<F32>}

law digest.e:
  for a: F32
  for b: F32
  for c: F32
  for d: F32
  for m: Array<F32>
  U32

def digest.e(a, b, c, d, m):
  F32.to_u32(F32.add(F32.add(F32.add(F32.mul(a, fl(1000, 1)), F32.mul(b, fl(100, 1))), F32.mul(c, fl(10, 1))), d))

law digest.d:
  for a: F32
  for b: F32
  for c: F32
  for m: Array<F32>
  U32

law digest.d.go:
  for a: F32
  for b: F32
  for c: F32
  for w: Array<F32> & F32
  U32

def digest.d.go(a, b, c, w):
  (m4, d) = w
  digest.e(a, b, c, d, m4)

def digest.d(a, b, c, m):
  digest.d.go(a, b, c, rd(m, 3))

law digest.c:
  for a: F32
  for b: F32
  for m: Array<F32>
  U32

law digest.c.go:
  for a: F32
  for b: F32
  for w: Array<F32> & F32
  U32

def digest.c.go(a, b, w):
  (m3, c) = w
  digest.d(a, b, c, m3)

def digest.c(a, b, m):
  digest.c.go(a, b, rd(m, 2))

law digest.b:
  for a: F32
  for m: Array<F32>
  U32

law digest.b.go:
  for a: F32
  for w: Array<F32> & F32
  U32

def digest.b.go(a, w):
  (m2, b) = w
  digest.c(a, b, m2)

def digest.b(a, m):
  digest.b.go(a, rd(m, 1))

law digest:
  for m: Array<F32>
  U32

law digest.go:
  for w: Array<F32> & F32
  U32

def digest.go(w):
  (m1, a) = w
  digest.b(a, m1)

def digest(m):
  digest.go(rd(m, 0))

law main.out:
  U32

def main.out():
  digest(rounds(3n, build()))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|653
