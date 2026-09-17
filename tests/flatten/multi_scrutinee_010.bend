type Nat is Data:
  Z{}
  S{p: Nat}

type R is Data:
  A{}
  B{a: Nat, b: Nat, c: Nat}

law main:
  for a: Nat
  for b: Nat
  for c: Nat
  R

def main(a, b, c):
  match a, b, c:
    case Z{}, a, b:
      A{}
    case S{a}, b, c:
      B{S{a}, b, c}

#|\{Z: (b => c => A{}); S: (a => b => c => B{S{a}, b, c})}
