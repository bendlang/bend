type Nat is Data:
  Z{}
  S{p: Nat}

type R is Data:
  A{x: Nat}
  B{x: Nat, y: Nat}
  C{x: Nat, y: Nat}

law main:
  for a: Nat
  for b: Nat
  R

def main(a, b):
  match a, b:
    case S{a}, Z{}:
      A{a}
    case S{a}, b:
      B{a,b}
    case a, b:
      C{a,b}

#|\{S: (a => \{Z: A{a}; (b => B{a, b})}); (a => b => C{a, b})}
