# Preserve a template match function that returns an argument and result type.
import Base

law via:
  for ~F: Bool -> Type
  for x: F(True{})
  F(True{})

def via(F, x):
  x

def use(u: Unit) -> Unit:
  via(~(\{True: Unit; False: Bool}), u)

#|ALL PROOFS CHECK
#|Use --verdict for mathematical validity.
