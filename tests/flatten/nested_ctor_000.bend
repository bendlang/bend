type Nat is Data:
  Z{}
  S{p: Nat}

type R is Data:
  A{}
  B{}
  C{x: Nat}

law main:
  for a: Nat
  R

def main(a):
  match a:
    case Z{}:
      A{}
    case S{Z{}}:
      B{}
    case S{S{a}}:
      C{a}

#|\{Z: A{}; S: \{Z: B{}; S: (a => C{a})}}
