# nested field match with an inner DEFAULT arm: the catch-all closes the
# inner level, binding the field's value
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
        case S{c}:
          c
        case w:
          S{w}

#|\{Z: Z{}; S: \{S: (c => c); (b => S{b})}}
