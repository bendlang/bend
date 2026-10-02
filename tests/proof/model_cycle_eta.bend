import Base

def Fam(n: Nat) -> Type:
  Nat

type R<-F: Nat -> Type> is Type:
  C{rest: R<(x => Fam(x))>}
  N{}

def is_c(r: R<Fam>) -> Bool:
  match r:
    case C{rest}:
      True{}
    case N{}:
      False{}

law t:
  for ~mk: Nat -> R<Fam>
  for ~ok: @x: Nat -> {is_c(mk(x)) == True{} : Bool}
  for x: Nat
  {is_c(mk(x)) == True{} : Bool}

def t(mk, ok, x):
  ok(x)

#|ALL PROOFS CHECK
#|Use --verdict for mathematical validity.
