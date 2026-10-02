# a model cannot use the same affine hypothesis in both constructor fields.
import Base

def use(~f: @A: Type -> A -> A & A, x: Nat) -> Nat & Nat:
  f(Nat, x)

#|ALL PROOFS CHECK
#|Use --verdict for mathematical validity.
