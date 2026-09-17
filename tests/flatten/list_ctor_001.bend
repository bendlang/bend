type Nat is Data:
  Z{}
  S{p: Nat}

type List<a, -Elem: Kind(a)> is Kind(a):
  Nil{}
  Cons{h: Elem, t: List<a, Elem>}

type R is Data:
  A{a: Nat, b: List<&2, Nat>}
  B{a: List<&2, Nat>}
  C{}

law main:
  for a: List<&2, Nat>
  R

def main(a):
  match a:
    case Cons{S{a}, b}:
      A{a,b}
    case Cons{Z{}, a}:
      B{a}
    case Nil{}:
      C{}

#|\{Cons: \{S: (a => b => A{a, b}); Z: (b => B{b})}; Nil: C{}}
