# multi-column outer, field-match inner: both params eliminate as columns
# and the inner statement refines the second's field
type Nat is Data:
  Z{}
  S{p: Nat}

law main:
  for a: Nat
  for b: Nat
  Nat

def main(a, b):
  match a, b:
    case Z{}, y:
      y
    case S{x}, Z{}:
      x
    case S{x}, S{y}:
      match y:
        case Z{}:
          x
        case S{p}:
          p

#|\{Z: (b => b); S: (x => \{Z: x; S: \{Z: x; S: (p => p)}})}
