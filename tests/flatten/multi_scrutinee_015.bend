# ported from bend3: the U32 column becomes a ctor word
type Nat is Data:
  Z{}
  S{p: Nat}

type MaybeNat is Data:
  None{}
  Some{x: Nat}

type W is Data:
  WZ{}
  WS{p: W}

law main:
  for a: MaybeNat
  for b: W
  MaybeNat

def main(a, b):
  match a, b:
    case None{}, a:
      None{}
    case Some{a}, b:
      Some{a}

#|\{None: (b => None{}); Some: (a => b => Some{a})}
