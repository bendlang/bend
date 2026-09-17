type Nat is Data:
  Z{}
  S{p: Nat}

type R is Data:
  A{}
  B{x: Nat}

law main:
  for a: Nat
  R

def main(a):
  match a:
    case Z{}:
      A{}
    case S{a}:
      B{a}

#|\{Z: A{}; S: (a => B{a})}
