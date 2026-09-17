type Nat is Data:
  Z{}
  S{p: Nat}

type R is Data:
  A{}
  B{x: Nat, y: Nat}

law main:
  for a: Nat
  for b: Nat
  for c: Nat
  R

def main(a, b, c):
  match a, b, c:
    case Z{}, b, Z{}:
      A{}
    case a, b, c:
      B{a,c}

#|\{Z: (b => \{Z: A{}; (c => B{Z{}, c})}); (a => b => c => B{a, c})}
