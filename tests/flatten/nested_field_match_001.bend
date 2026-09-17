# nested match on fields, three levels deep: each level is a match
# statement on the previous level's field binder
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
    case S{b}:
      match b:
        case Z{}:
          Z{}
        case S{c}:
          match c:
            case Z{}:
              Z{}
            case S{d}:
              d

#|\{Z: Z{}; S: \{Z: Z{}; S: \{Z: Z{}; S: (d => d)}}}
