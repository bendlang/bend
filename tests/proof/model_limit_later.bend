# a limited fallback can check itself, but cannot choose later constants
# the next root is independent and must still go out normally
import Base

type B<-A: Type> is Type:
  Fork{l: B<Pair(A, A)>, m: B<Pair(A, A)>, r: B<Pair(A, A)>}
  Tip{}

def limited(~b: B<Nat>, ~n: Nat) -> {b == b : B<Nat>}:
  {==}

def independent(~n: Nat) -> {n == n : Nat}:
  {==}

#|ALL PROOFS CHECK
#|Use --verdict for mathematical validity.
