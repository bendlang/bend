# deep source pattern PLUS a field-match statement: case S{S{b}} digs two
# levels, then a match statement digs the third
type Nat is Data:
  Z{}
  S{p: Nat}

law main:
  for a: Nat
  Nat

def main(a):
  match a:
    case Z{}:
      Z{}
    case S{Z{}}:
      Z{}
    case S{S{b}}:
      match b:
        case Z{}:
          Z{}
        case S{c}:
          c

#|\{Z: Z{}; S: \{Z: Z{}; S: \{Z: Z{}; S: (c => c)}}}
