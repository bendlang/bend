type Nat is Data:
  Z{}
  S{p: Nat}

type R is Data:
  A{}
  B{x: Nat, y: Nat}

law main:
  for a: Nat
  for b: Nat
  R

def main(a, b):
  match a, b:
    case Z{}, Z{}:
      A{}
    case x, y:
      B{x, y}

#|\{Z: \{Z: A{}; (b => B{Z{}, b})}; (a => b => B{a, b})}
