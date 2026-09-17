type Nat is Data:
  Z{}
  S{p: Nat}

type MaybeNat is Data:
  None{}
  Some{x: Nat}

law main:
  for a: MaybeNat
  MaybeNat

def main(a):
  match a:
    case None{}:
      None{}
    case Some{a}:
      Some{a}

#|\{None: None{}; Some: (a => Some{a})}
