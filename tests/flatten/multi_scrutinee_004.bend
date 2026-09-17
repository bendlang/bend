type Nat is Data:
  Z{}
  S{p: Nat}

type R is Data:
  A{a: Nat, b: Nat}
  B{a: Nat}
  C{b: Nat}
  D{}

law main:
  for a: Nat
  for b: Nat
  R

def main(a, b):
  match a, b:
    case S{a}, S{b}:
      A{a,b}
    case S{a}, Z{}:
      B{a}
    case Z{}, S{b}:
      C{b}
    case Z{}, Z{}:
      D{}

#|\{S: (a => \{S: (b => A{a, b}); Z: B{a}}); Z: \{S: (b => C{b}); Z: D{}}}
