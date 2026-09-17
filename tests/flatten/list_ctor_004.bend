type Nat is Data:
  Z{}
  S{p: Nat}
type List<a, -Elem: Kind(a)> is Kind(a):
  Nil{}
  Cons{h: Elem, t: List<a, Elem>}
type R is Data:
  A{}
  B{a: Nat, b: List<&2, Nat>}
  C{a: Nat, b: List<&2, Nat>, c: List<&2, Nat>}
  D{a: Nat, b: Nat, c: List<&2, Nat>, d: List<&2, Nat>}

law main:
  for a: Nat
  for b: List<&2, Nat>
  for c: List<&2, Nat>
  R

def main(a, b, c):
  match a, b, c:
    case Z{}, a, b:
      A{}
    case S{a}, Nil{}, b:
      B{a,b}
    case S{a}, Cons{Z{}, b}, c:
      C{a,b,c}
    case S{a}, Cons{S{b}, c}, d:
      D{a,b,c,d}

#|\{Z: (b => c => A{}); S: (a => \{Nil: (c => B{a, c}); Cons: \{Z: (b => c => C{a, b, c}); S: (b => b => c => D{a, b^1, b, c})}})}
