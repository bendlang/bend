type Nat is Data:
  Z{}
  S{p: Nat}

type R is Data:
  A{}
  B{x: Nat, y: Nat}
  C{x: Nat, y: Nat, z: Nat}

law main:
  for a: Nat
  for b: Nat
  for c: Nat
  R

def main(a, b, c):
  match a, b, c:
    case Z{}, b, Z{}:
      A{}
    case Z{}, b, S{y}:
      B{y,b}
    case S{x}, b, y:
      C{x,y,b}

#|\{Z: (b => \{Z: A{}; S: (y => B{y, b})}); S: (x => b => c => C{x, c, b})}
