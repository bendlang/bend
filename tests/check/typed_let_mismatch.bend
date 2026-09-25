# the type of a typed let is checked against its value
import Base

def main() -> U32:
  z : Nat = 30
  0
#|Error:
#|- expected : Nat
#|- observed : U32
#|Location: main
#|4 | def main() -> U32:
#|5>|   z : Nat = 30
#|  |             ^^
#|6 |   0
#|exit 1
