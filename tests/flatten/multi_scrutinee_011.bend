type Nat is Data:
  Z{}
  S{p: Nat}

law main:
  for a: Nat
  for b: Nat
  Nat

def main(a, b):
  match a, b:
    case Z{}, a:
      a
    case S{a}, b:
      a

#|\{Z: (b => b); S: (a => b => a)}
