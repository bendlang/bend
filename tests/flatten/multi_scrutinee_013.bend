type Nat is Data:
  Z{}
  S{p: Nat}

type R is Data:
  A{}
  B{x: Nat}
  C{x: Nat}
  D{x: Nat, y: Nat}

law main:
  for a: Nat
  for b: Nat
  for c: Nat
  R

def main(a, b, c):
  match a, b, c:
    case Z{}, Z{}, c:
      A{}
    case Z{}, x, c:
      B{x}
    case y, Z{}, c:
      C{y}
    case y, x, c:
      D{y, x}

#|\{Z: \{Z: (c => A{}); (b => c => B{b})}; (a => \{Z: (c => C{a}); (b => c => D{a, b})})}
