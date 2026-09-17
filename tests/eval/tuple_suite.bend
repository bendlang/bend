# tuples end to end: (a,b) values (right-nested), tuple destructuring
# in defs and match arms, type-level (A & B) and &x:A -> B, and a
# generic swap through the dependent Pair -- pure, so the compiled
# lanes cover the Tuple ctor through the C backend too.
# ported from bend3: literal tuple patterns (case (4, 3)) become a
# destructure plus U32.is_eq checks (bend has no word patterns);
# result 118 (bend3's golden) shown as a Nat
import Base

law swap:
  for -A: Type
  for -B: Type
  for  p: (A & B)
  (B & A)

def swap(A, B, p):
  (a, b) = p
  (b, a)

law dep:
  for p: &x:U32 -> (U32 & U32)
  U32

def dep(p):
  (x, y, z) = p
  U32.add(U32.add(x, y), z)

law check:
  for q: (U32 & U32)
  U32

law check.if:
  for z: Bool
  U32

def check.if(z):
  match z:
    case True{}:
      U32.add(100, dep((5, 6, 7)))
    case False{}:
      0

def check(q):
  (qa, qb) = q
  check.if(Bool.and(U32.is_eq(qa, 4), U32.is_eq(qb, 3)))

law main.out:
  Nat

def main.out():
  U32.to_nat(check(swap(U32, U32, (3, 4))))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|118n
