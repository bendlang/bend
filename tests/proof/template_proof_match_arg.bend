# A match passed to a λ in a later domain keeps its type.
import Base

law via:
  for ~f: Bool -> Bool
  for ~P: (Bool -> Bool) -> Type
  for p: P(f)
  Unit

def via(f, P, p):
  Unit{}

def use(u: Unit) -> Unit:
  via(~(\{True: True{}; False: False{}}), ~(h => @b: Bool -> {h(b) == h(b) : Bool}), b => {==})

#|ALL PROOFS CHECK
#|Use --verdict for mathematical validity.
