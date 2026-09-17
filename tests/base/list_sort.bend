# List.sort (32-pass binary radix) on small, empty and high-bit inputs
# ported from bend3: bend-base's radix sort is inlined over bend's List
# (Nil/Con) with the bit index as Nat; List.get becomes lget with a Nat
# index; strict -- the helper defs folded into their callers' case
# trees, shared words and bit indexes bind + (Data)
import Base

law bu:
  for b: Bool
  U32

def bu(b):
  match b:
    case False{}:
      0
    case True{}:
      1

law lconcat:
  for xs: List<&2, U32>
  for ys: List<&2, U32>
  List<&2, U32>

def lconcat(xs, ys):
  match xs:
    case Nil{}:
      ys
    case h <> t:
      h <> lconcat(t, ys)

law lrev.go:
  for xs  : List<&2, U32>
  for acc : List<&2, U32>
  List<&2, U32>

def lrev.go(xs, acc):
  match xs:
    case Nil{}:
      acc
    case h <> t:
      lrev.go(t, h <> acc)

law lrev:
  for xs: List<&2, U32>
  List<&2, U32>

def lrev(xs):
  lrev.go(xs, Nil{})

law spass.go:
  for +b : Nat
  for xs : List<&2, U32>
  for h  : U32
  for f  : Bool
  for zs : List<&2, U32>
  for os : List<&2, U32>
  List<&2, U32>

def spass.go(b, xs, h, f, zs, os):
  match xs f:
    case +h0 <> t True{}:
      spass.go(b, t, h0, U32.is_zero(U32.and(U32.shrn(h0, b), 1)), h <> zs, os)
    case +h0 <> t False{}:
      spass.go(b, t, h0, U32.is_zero(U32.and(U32.shrn(h0, b), 1)), zs, h <> os)
    case Nil{} True{}:
      lconcat(lrev(h <> zs), lrev(os))
    case Nil{} False{}:
      lconcat(lrev(zs), lrev(h <> os))

law spass:
  for +b : Nat
  for xs : List<&2, U32>
  for zs : List<&2, U32>
  for os : List<&2, U32>
  List<&2, U32>

def spass(b, xs, zs, os):
  match xs:
    case +h0 <> t:
      spass.go(b, t, h0, U32.is_zero(U32.and(U32.shrn(h0, b), 1)), zs, os)
    case Nil{}:
      lconcat(lrev(zs), lrev(os))

law sgo:
  for k  : Nat
  for +b : Nat
  for xs : List<&2, U32>
  List<&2, U32>

def sgo(k, b, xs):
  match k:
    case 0n:
      xs
    case 1n+j:
      sgo(j, 1n+b, spass(b, xs, Nil{}, Nil{}))

law lsort:
  for xs: List<&2, U32>
  List<&2, U32>

def lsort(xs):
  sgo(32n, 0n, xs)

law digest.go:
  for xs  : List<&2, U32>
  for acc : U32
  U32

def digest.go(xs, acc):
  match xs:
    case Nil{}:
      acc
    case h <> t:
      digest.go(t, U32.add(U32.mul(acc, 10), h))

law digest:
  for xs: List<&2, U32>
  U32

def digest(xs):
  digest.go(xs, 0)

law lget.put:
  for h: U32
  for r: List<&2, U32> & U32
  (List<&2, U32> & U32)

def lget.put(h, r):
  (t2, x) = r
  (h <> t2, x)

law lget:
  for d  : U32
  for i  : Nat
  for xs : List<&2, U32>
  (List<&2, U32> & U32)

def lget(d, i, xs):
  match i xs:
    case 0n Nil{}:
      (Nil{}, d)
    case 0n +h0 <> t:
      (h0 <> t, h0)
    case 1n+p Nil{}:
      (Nil{}, d)
    case 1n+p h <> t:
      lget.put(h, lget(d, p, t))

law big.c:
  for x: U32
  for y: U32
  for r: List<&2, U32> & U32
  U32

def big.c(x, y, r):
  (b3, z) = r
  m3 = bu(U32.is_eq(x, 0))
  m4 = bu(U32.is_eq(y, 2147483648))
  m5 = bu(U32.is_eq(z, 4294967295))
  U32.add(U32.add(m3, m4), m5)

law big.b:
  for x: U32
  for r: List<&2, U32> & U32
  U32

def big.b(x, r):
  (b2, y) = r
  big.c(x, y, lget(99, 2n, b2))

law big.a:
  for r: List<&2, U32> & U32
  U32

def big.a(r):
  (b1, x) = r
  big.b(x, lget(99, 1n, b1))

law big.x:
  for big: List<&2, U32>
  U32

def big.x(big):
  big.a(lget(99, 0n, big))

law main.out:
  U32

def main.out():
  b0 = bu(U32.is_eq(digest(lsort([5, 3, 9, 1, 4])), 13459))
  b1 = bu(U32.is_eq(digest(lsort(Nil{})), 0))
  b2 = bu(U32.is_eq(digest(lsort([1, 2, 3])), 123))
  U32.add(U32.add(U32.add(b0, b1), b2), big.x(lsort([4294967295, 0, 2147483648])))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|6
