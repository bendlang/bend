type Nat is Data:
  Z{}
  S{p: Nat}

law main:
  for a: Nat
  for b: Nat
  for c: Nat
  Nat

def main(a, b, c):
  match a, b, c:
    case Z{}, a, b:
      a
    case S{a}, b, c:
      b

#|\{Z: (b => c => b); S: (a => b => c => b)}
