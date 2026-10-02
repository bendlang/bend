import Base

type B<-A: Type> is Type:
  Fork{l: B<Pair(A, A)>, m: B<Pair(A, A)>, r: B<Pair(A, A)>}
  Tip{}

def reflexive(~b: B<Nat>) -> {b == b : B<Nat>}:
  {==}

#|ALL PROOFS CHECK
#|Use --verdict for mathematical validity.
