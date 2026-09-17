# destructure of a FIELD: a case arm binds a field, a statement then
# destructures it
type Nat is Data:
  Z{}
  S{p: Nat}

type Pair is Data:
  P{a: Nat, b: Nat}

type Box is Data:
  Box{v: Pair}

law main:
  for w: Box
  Nat

def main(w):
  match w:
    case Box{v}:
      P{a, b} = v
      a

#|\{Box: \{P: (a => b => a)}}
