# a rigid-in-b var-in-a row (`c Z{}`) survives every a-branch: the
# a-column's tags {S,Z} cover Nat, the dead residue is elided, and each
# branch's b-match ends complete -- the priority-ordered match checks
# ported from bend3: the flattener must accept and the program answer
type Nat is Data:
  Z{}
  S{p: Nat}

type R is Data:
  A{a: Nat, b: Nat}
  B{b: Nat}
  C{c: Nat}

law f:
  for a: Nat
  for b: Nat
  R

def f(a, b):
  match a, b:
    case S{a}, S{b}:
      A{a, b}
    case Z{}, S{b}:
      B{b}
    case c, Z{}:
      C{c}

law main:
  R

def main():
  f(S{Z{}}, Z{})

#|C{S{Z{}}}
