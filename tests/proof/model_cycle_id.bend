import Base

def Id(A: Type) -> Type:
  A

type R<-A: Type> is Type:
  C{rest: R<Nat>}
  N{}

def is_c(r: R<Id(Nat)>) -> Bool:
  match r:
    case C{rest}:
      True{}
    case N{}:
      False{}

law t:
  for ~mk: Nat -> R<Id(Nat)>
  for ~ok: @x: Nat -> {is_c(mk(x)) == True{} : Bool}
  for x: Nat
  {is_c(mk(x)) == True{} : Bool}

def t(mk, ok, x):
  ok(x)

#|ALL PROOFS CHECK
#|Use --verdict for mathematical validity.
