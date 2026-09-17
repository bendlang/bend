# field x param mix: a match on the first param's FIELD, then a match on
# the second PARAM inside its S arm
type Nat is Data:
  Z{}
  S{p: Nat}

law main:
  for a: Nat
  for b: Nat
  Nat

def main(a, b):
  match a:
    case Z{}:
      b
    case S{x}:
      match x:
        case Z{}:
          b
        case S{z}:
          match b:
            case Z{}:
              z
            case S{y}:
              y

#|\{Z: (b => b); S: \{Z: (b => b); S: (z => \{Z: z; S: (y => y)})}}
