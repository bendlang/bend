# the six U32 comparisons yield exactly 0/1 across lt/eq/gt operand pairs
# ported from bend3: each infix comparison becomes bu(U32.is_*)
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

law row:
  for a: U32
  for b: U32
  for c: U32
  U32

def row(a, b, c):
  U32.add(U32.add(a, U32.mul(b, 10)), U32.mul(c, 100))

law main.out:
  U32

def main.out():
  c0 = bu(U32.is_eq(row(bu(U32.is_lt(2, 3)), bu(U32.is_lt(3, 3)), bu(U32.is_lt(4, 3))), 1))
  c1 = bu(U32.is_eq(row(bu(U32.is_le(2, 3)), bu(U32.is_le(3, 3)), bu(U32.is_le(4, 3))), 11))
  c2 = bu(U32.is_eq(row(bu(U32.is_gt(2, 3)), bu(U32.is_gt(3, 3)), bu(U32.is_gt(4, 3))), 100))
  c3 = bu(U32.is_eq(row(bu(U32.is_ge(2, 3)), bu(U32.is_ge(3, 3)), bu(U32.is_ge(4, 3))), 110))
  c4 = bu(U32.is_eq(row(bu(U32.is_eq(2, 3)), bu(U32.is_eq(3, 3)), bu(U32.is_eq(4, 3))), 10))
  c5 = bu(U32.is_eq(row(bu(U32.is_ne(2, 3)), bu(U32.is_ne(3, 3)), bu(U32.is_ne(4, 3))), 101))
  U32.add(U32.add(U32.add(U32.add(U32.add(c0, c1), c2), c3), c4), c5)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|6
