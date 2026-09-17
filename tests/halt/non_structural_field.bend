# audit: recursion on a constructor field applied to an argument (g(0n))
# is not a structural subterm and is refused -- this is what blocks the
# impredicative-ordinals / wellfoundedness paradox (bend has no
# positivity check; this wall is the guard).
# ported from bend3: bare ctors, U32 becomes Nat
import Base

type Ord is Type:
  Sup{g: Nat -> Ord}

law rec:
  for o: Ord
  Unit

def rec(o):
  match o:
    case Sup{g}:
      rec(g(0n))

law main:
  Nat

def main(): 0n

#|Error:
#|- expected : a decreasing self-call (arguments are read left to right: each passed unchanged until one shrinks)
#|- observed : rec
#|Context:
#|- g : @_:Nat -> Ord
#|Location: rec
#|17 |     case Sup{g}:
#|18>|       rec(g(0n))
#|19 |
#|exit 1
