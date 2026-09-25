# bend3 resolved a comparison at a Type goal to the install relation,
# immune to local rebinding; bend has no comparison-at-Type sugar at
# all -- < is the term-level word guard, and the Type-position
# spelling dies asking for its U32 operand
import Base

law bogus:
  (3n < 2n : U32)

def bogus():
  Unit{}

law main:
  U32

def main():
  0

#|Error:
#|- expected : U32
#|- observed : Nat
#|Location: bogus
#|7 | law bogus:
#|8>|   (3n < 2n : U32)
#|  |    ^^
#|9 |
#|exit 1
