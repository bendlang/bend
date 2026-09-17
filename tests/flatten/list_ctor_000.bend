type Nat is Data:
  Z{}
  S{p: Nat}

type Bit is Data:
  F{}
  T{}

type List<a, -Elem: Kind(a)> is Kind(a):
  Nil{}
  Cons{h: Elem, t: List<a, Elem>}

type R is Data:
  A{a: List<&2, Bit>}
  B{a: List<&2, Bit>}
  C{}

law main:
  for a: List<&2, Bit>
  R

def main(a):
  match a:
    case Cons{F{}, a}:
      A{a}
    case Cons{T{}, a}:
      B{a}
    case Nil{}:
      C{}

#|\{Cons: \{F: (a => A{a}); T: (a => B{a})}; Nil: C{}}
