# a constructor-local grade never reaches the declared kind: an erased
# grade and kind bound inside the constructor's own telescope leave the
# live val: T at Kind(a), which the Data declaration does not entail,
# so the field refuses exactly like a datatype-level parameter
import Base

type Box is Data:
  Wrap{a, -T: Kind(a), val: T}

law main:
  Nat

def main():
  0n

#|Error:
#|- expected : Data
#|- observed : Kind(a)
#|Context:
#|- a : Quant
#|- T : Kind(a)
#|Location: Wrap
#|7 | type Box is Data:
#|8>|   Wrap{a, -T: Kind(a), val: T}
#|  |                             ^
#|9 |
#|exit 1
