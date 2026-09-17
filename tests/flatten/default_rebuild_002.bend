type Nat is Data:
  Z{}
  S{p: Nat}

type List<a, -Elem: Kind(a)> is Kind(a):
  Nil{}
  Cons{h: Elem, t: List<a, Elem>}

type R is Data:
  A{a: Nat, b: List<&2, Nat>}
  B{a: Nat, b: List<&2, Nat>}
  C{}

law main:
  for a: List<&2, Nat>
  R

def main(a):
  match a:
    case Cons{S{S{a}}, b}:
      A{a,b}
    case Cons{a, b}:
      B{a,b}
    case Nil{}:
      C{}

#|\{Cons: \{S: \{S: (a => b => A{a, b}); (_8 => b => B{S{_8}, b})}; (_7 => b => B{_7, b})}; Nil: C{}}
