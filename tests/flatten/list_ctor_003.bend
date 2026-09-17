type Nat is Data:
  Z{}
  S{p: Nat}
type List<a, -Elem: Kind(a)> is Kind(a):
  Nil{}
  Cons{h: Elem, t: List<a, Elem>}
type R is Data:
  A{a: Nat, b: List<&2, Nat>}
  B{}
  C{a: Nat, b: List<&2, Nat>}
  D{}

law main:
  for a: List<&2, Nat>
  R

def main(a):
  match a:
    case Cons{S{a}, b}:
      A{a,b}
    case Cons{Z{}, Nil{}}:
      B{}
    case Cons{Z{}, Cons{a, b}}:
      C{a,b}
    case Nil{}:
      D{}

#|\{Cons: \{S: (a => b => A{a, b}); Z: \{Nil: B{}; Cons: (a => b => C{a, b})}}; Nil: D{}}
