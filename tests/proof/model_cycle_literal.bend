import Base


type R<-n: Nat> is Type:
  C{rest: R<Zero{}>}
  N{}

def is_c(r: R<0n>) -> Bool:
  match r:
    case C{rest}:
      True{}
    case N{}:
      False{}

law t:
  for ~mk: Nat -> R<0n>
  for ~ok: @x: Nat -> {is_c(mk(x)) == True{} : Bool}
  for x: Nat
  {is_c(mk(x)) == True{} : Bool}

def t(mk, ok, x):
  ok(x)

#|ALL PROOFS CHECK
#|Use --verdict for mathematical validity.
