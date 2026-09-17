# ndiv(n, 2n) is not a structural subterm of n: the loop terminates at runtime,
# but the descent judgment refuses it (bend has no opt-out, so the runnable half
# of the bend3 test has no place in this file).
# ported from bend3: U32 halving becomes ndiv
import Base

law ndiv:
  for a: Nat
  for b: Nat
  Nat

law ndiv.fin:
  for qr: Nat & Nat
  Nat

def ndiv.fin(qr):
  (q, r) = qr
  q

def ndiv(a, b):
  ndiv.fin(Nat.divmod(a, b))

law fold:
  for n: Nat
  Nat

def fold(n):
  match n:
    case 0n:
      0n
    case n:
      1n+ fold(ndiv(n, 2n))

law main:
  Nat

def main(): fold(10n)

#|Error:
#|- expected : a decreasing self-call (arguments are read left to right: each passed unchanged until one shrinks)
#|- observed : fold
#|Context:
#|- n : Nat<> - Zero{}
#|Location: fold
#|31 |     case n:
#|32>|       1n+ fold(ndiv(n, 2n))
#|33 |
#|exit 1
