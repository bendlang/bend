# unary Nat at runtime: add/mul/sub (truncating) and the u32 bridge
# ported from bend3: Nat.to_u32/from_u32 become U32.from_nat/U32.to_nat
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
  b0 = bu(U32.is_eq(U32.from_nat(Nat.add(2n, 3n)), 5))
  b1 = bu(U32.is_eq(U32.from_nat(Nat.mul(3n, 4n)), 12))
  b2 = bu(U32.is_eq(U32.from_nat(Nat.sub(5n, 2n)), 3))
  b3 = bu(U32.is_eq(U32.from_nat(Nat.sub(2n, 5n)), 0))
  b4 = bu(U32.is_eq(U32.from_nat(U32.to_nat(9)), 9))
  U32.add(U32.add(U32.add(U32.add(b0, b1), b2), b3), b4)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|5
