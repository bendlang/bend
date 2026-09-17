type Nat is Data:
  Z{}
  S{p: Nat}

type R is Data:
  A{x: Nat}
  B{x: Nat, y: Nat}

law main:
  for a: Nat
  for b: Nat
  R

def main(a, b):
  match a, b:
    case Z{}, b:
      A{b}
    case a, b:
      B{a,b}

#|\{Z: (b => A{b}); (a => b => B{a, b})}
