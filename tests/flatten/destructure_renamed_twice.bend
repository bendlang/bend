# a var row renames y to the scrutinee w, a destructure of y then splits w
# itself, and a match on the field a it bound splits again: y passes
# through a rename, w through its own var column and then its ctr, in
# that order, in each row
type Nat is Data:
  Z{}
  S{p: Nat}

type Pair is Data:
  P{a: Nat, b: Nat}

law main:
  for k: Nat
  for w: Pair
  Nat

def main(k, w):
  match k, w:
    case Z{}, y:
      P{a, b} = y
      match a:
        case S{c}:
          c
        case d:
          b
    case S{j}, y:
      P{a, b} = y
      b
#|\{Z: \{P: \{S: (c => b => c); (a => b => b)}}; S: (j => \{P: (a => b => b)})}
