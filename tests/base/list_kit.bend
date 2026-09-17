# the affine base List kit: get/set at Nat indexes (Maybe out, OOB set
# is a no-op), head/tail/is_empty edges, concat, and zip's pair walk --
# nine checks packed positionally into one U32
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

law digit99:
  for m: Maybe<&2, U32>
  U32

def digit99(m):
  Maybe.default(&2, U32, m, 99)

law l4:
  List<&2, U32>

def l4():
  [10, 20, 30, 40]

law l2:
  List<&2, U32>

def l2():
  [1, 2]

law zsum:
  for xs: List<&1, U32 & U32>
  U32

def zsum(xs):
  match xs:
    case Nil{}:
      0
    case (x, y) <> t:
      U32.add(U32.add(x, y), zsum(t))

law nlen:
  for xs: List<&2, U32>
  U32

def nlen(xs):
  U32.from_nat(List.length(&2, U32, xs))

law main.out:
  U32

def main.out():
  b0 = bu(U32.is_eq(digit99(List.get(&2, U32, l4(), 2n)), 30))
  b1 = bu(U32.is_eq(digit99(List.get(&2, U32, l4(), 7n)), 99))
  b2 = bu(U32.is_eq(digit99(List.head(&2, U32, List.set(&2, U32, l2(), 0n, 5))), 5))
  b3 = bu(U32.is_eq(nlen(List.set(&2, U32, l2(), 5n, 9)), 2))
  b4 = bu(U32.is_eq(nlen(List.concat(&2, U32, [[1], [2, 3]])), 3))
  b5 = bu(U32.is_eq(zsum(List.zip(&2, U32, &2, U32, [1, 2, 3], [4, 5])), 12))
  b6 = bu(U32.is_eq(digit99(List.head(&2, U32, List.tail(&2, U32, [7, 8]))), 8))
  b7 = bu(List.is_empty(&2, U32, Nil{}))
  b8 = bu(Bool.not(List.is_empty(&2, U32, l2())))
  d0 = U32.add(U32.mul(b0, 10), b1)
  d1 = U32.add(U32.mul(d0, 10), b2)
  d2 = U32.add(U32.mul(d1, 10), b3)
  d3 = U32.add(U32.mul(d2, 10), b4)
  d4 = U32.add(U32.mul(d3, 10), b5)
  d5 = U32.add(U32.mul(d4, 10), b6)
  d6 = U32.add(U32.mul(d5, 10), b7)
  U32.add(U32.mul(d6, 10), b8)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|111111111
