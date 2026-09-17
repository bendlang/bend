type Nat is Data:
  Z{}
  S{p: Nat}

type R is Data:
  F{x: Nat, y: Nat}
  G{x: Nat, y: Nat, z: Nat}

law main:
  for A: Type
  for b: Nat
  for c: Nat
  for d: Nat
  R

def main(A, b, c, d):
  match A, b, c, d:
    case A, x, Z{}, z:
      F{x,z}
    case A, x, S{n}, z:
      G{x,n,z}

#|A => b => \{Z: (d => F{b, d}); S: (n => d => G{b, n, d})}
