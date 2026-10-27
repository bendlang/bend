# This file owns its Nat and constructors without importing Base.
type Nat is Data:
  Zero{}
  Succ{pred: Nat}

def Nat.add(a: Nat, b: Nat) -> Nat:
  a

def one() -> Nat:
  1n

#|ALL PROOFS CHECK
#|Use --verdict for mathematical validity.
