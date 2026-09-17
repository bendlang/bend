# U32 division and modulo: total (x/0 = 0, x%0 = x), truncating, max-value edges
# ported from bend3: infix / and % become U32.div/U32.mod
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

law main.out:
  U32

def main.out():
  b0 = bu(U32.is_eq(U32.div(7, 0), 0))
  b1 = bu(U32.is_eq(U32.mod(7, 0), 7))
  b2 = bu(U32.is_eq(U32.div(0, 5), 0))
  b3 = bu(U32.is_eq(U32.div(17, 5), 3))
  b4 = bu(U32.is_eq(U32.mod(17, 5), 2))
  b5 = bu(U32.is_eq(U32.div(4294967295, 10), 429496729))
  b6 = bu(U32.is_eq(U32.mod(4294967295, 10), 5))
  b7 = bu(U32.is_eq(U32.div(1, 4294967295), 0))
  b8 = bu(U32.is_eq(U32.div(4294967295, 4294967295), 1))
  U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(b0, b1), b2), b3), b4), b5), b6), b7), b8)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|9
