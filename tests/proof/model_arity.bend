import Base
type G<-A: Type> is Type:
  Leaf{a: A, b: A}
  Grow{rest: G<Pair(A, A)>}
def reflexive(~n: G<Nat>) -> {n == n : G<Nat>}:
  {==}

#|ALL PROOFS CHECK
#|Use --verdict for mathematical validity.

#>ALL PROOFS CHECK
