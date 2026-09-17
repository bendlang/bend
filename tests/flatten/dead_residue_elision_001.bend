# a var row PARTIAL in a later column (`a S{b}`) rides the a-chain's
# residue, but the chain's peeled tags {S,Z} cover Nat: the residue is
# dead, so the b-matches stay total and the match is semantically
# complete
# ported from bend3: the flattener must accept and the program answer
type Nat is Data:
  Z{}
  S{p: Nat}

type R is Data:
  A{a: Nat, b: Nat}
  B{a: Nat, b: Nat}
  C{}
  D{a: Nat}

law f:
  for a: Nat
  for b: Nat
  R

def f(a, b):
  match a, b:
    case S{a}, S{b}:
      A{a, b}
    case a, S{b}:
      B{a, b}
    case Z{}, Z{}:
      C{}
    case S{a}, Z{}:
      D{a}

law main:
  R

def main():
  f(Z{}, S{Z{}})

#|B{Z{}, Z{}}
