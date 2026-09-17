# nested match on a pattern FIELD: the inner match statement refines the
# field binder in place -- a direct two-level case tree, no aux
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
    case S{b}:
      match b:
        case Z{}:
          A{}
        case S{c}:
          B{c}

#|\{Z: A{}; S: \{Z: A{}; S: (c => B{c})}}
