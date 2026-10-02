# a growing first choice must not starve a later nonnullary model.
import Base

type Grow<-A: Type> is Type:
  More{next: Grow<Pair(A, A)>}
  Leaf{n: Nat}

def reflexive(~g: Grow<Nat>) -> {g == g : Grow<Nat>}:
  {==}

#|ALL PROOFS CHECK
#|Use --verdict for mathematical validity.
