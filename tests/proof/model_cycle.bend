# Equality recognizes the cycle even beneath a function-valued parameter.
import Base

type W<-F: Nat -> Type> is Type:
  C{g: Nat -> W<F>}

def reflexive(~w: W<(n => Nat)>) -> {w == w : W<(n => Nat)>}:
  {==}

#|ALL PROOFS CHECK
#|Use --verdict for mathematical validity.

#>SOME PROOFS FAIL
#>BendTT: out of scope:
#>- reflexive: names reflexive_7e_w, out of scope: no model for reflexive~w
