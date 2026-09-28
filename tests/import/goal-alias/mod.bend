# a module whose quad unfolds to its double
import Base

def double(n: Nat) -> Nat:
  match n:
    case 0n:
      0n
    case 1n+p:
      2n+double(p)

def quad(n: Nat) -> Nat:
  double(double(n))
