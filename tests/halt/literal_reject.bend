# descent at literal patterns, reject side: a self-call at a LARGER
# closed literal than the matched one is not a descent (7n is a strict
# superterm of the 5n column, not a subterm).
# ported from bend3: the U32 phase word becomes Nat literals
import Base

law f:
  for n: Nat
  Nat

def f(n):
  match n:
    case 5n:
      f(7n)
    case p:
      0n

law main:
  Nat

def main(): f(3n)

#|Error:
#|- expected : a decreasing self-call (arguments are read left to right: each passed unchanged until one shrinks)
#|- observed : f
#|Location: f
#|13 |     case 5n:
#|14>|       f(7n)
#|   |       ^
#|15 |     case p:
#|exit 1
