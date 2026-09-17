type Nat is Data:
  Z{}
  S{p: Nat}

type R is Data:
  A{x: Nat, y: Nat}
  B{x: Nat, y: Nat, z: Nat}
  C{x: Nat, y: Nat, z: Nat}

law main:
  for a: Nat
  for b: Nat
  for c: Nat
  for d: Nat
  R

def main(a, b, c, d):
  match a, b, c, d:
    case Z{}, b, c, Z{}:
      A{b,c}
    case Z{}, b, c, S{y}:
      B{y,b,c}
    case S{x}, b, c, y:
      C{x,y,c}

#|\{Z: (b => c => \{Z: A{b, c}; S: (y => B{y, b, c})}); S: (x => b => c => d => C{x, d, c})}
