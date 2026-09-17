type Nat is Data:
  Z{}
  S{p: Nat}
type List<a, -Elem: Kind(a)> is Kind(a):
  Nil{}
  Cons{h: Elem, t: List<a, Elem>}
type R is Data:
  A{a: Nat, b: Nat, c: List<&2, Nat>}
  B{a: Nat, b: List<&2, Nat>}
  C{}

law main:
  for a: List<&2, Nat>
  R

def main(a):
  match a:
    case Cons{S{a}, Cons{b, c}}:
      A{a,b,c}
    case Cons{a, b}:
      B{a,b}
    case Nil{}:
      C{}

#|\{Cons: \{S: (a => \{Cons: (b => c => A{a, b, c}); (_10 => B{S{a}, _10})}); (_9 => _10 => B{_9, _10})}; Nil: C{}}
