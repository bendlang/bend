# Preserve a template match function's type in a later parameter's domain.
import Base

law via:
  for ~f: Bool -> Bool
  for p: {f(True{}) == f(True{}) : Bool}
  Unit

def via(f, p):
  Unit{}

def use(u: Unit) -> Unit:
  via(~(\{True: True{}; False: False{}}), {==})

#|ALL PROOFS CHECK
#|Use --verdict for mathematical validity.
