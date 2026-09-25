# the + law binds Let formation: a + let binder licenses contraction,
# so its inferred type's kind must reduce to Data -- an opaque T: Type
# value cannot be rebound +
import Base

law dupl:
  for -T: Type
  for  a: T
  T & T

def dupl(T, a):
  +x = a
  (x, x)

law main:
  Nat & Nat

def main(): dupl(Nat, 1n)

#|Error:
#|- expected : Data
#|- observed : Type
#|Context:
#|- T : Type
#|- a : T
#|Location: dupl
#|11 | def dupl(T, a):
#|12>|   +x = a
#|   |   ^^^
#|13 |   (x, x)
#|exit 1
