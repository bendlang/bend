type Nat is Data:
  Z{}
  S{p: Nat}

type R is Data:
  A{a: Nat}
  B{a: Nat, b: Nat}
  C{a: Nat}

law main:
  for a: Nat
  for b: Nat
  R

def main(a, b):
  match a, b:
    case S{a}, S{Z{}}:
      A{a}
    case a, S{b}:
      B{a,b}
    case a, Z{}:
      C{a}

#|\{S: (a => \{S: \{Z: A{a}; (_6 => B{S{a}, _6})}; Z: C{S{a}}}); (a => \{S: (b => B{a, b}); Z: C{a}})}
