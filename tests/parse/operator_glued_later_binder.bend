# the glued `+` needn't be the second name of the binder list (#1510)
import Base

def add(x: U32, +y: U32, z: U32) -> U32:
  x y+z

def main() -> U32:
  add(1, 2, 3)

#|SOME PROOFS FAIL
#|Error:
#|- expected : '=' (an operator takes spaces on both sides and a type: (a + b : T))
#|- observed : '+'
#|Location:
#|4 | def add(x: U32, +y: U32, z: U32) -> U32:
#|5>|   x y+z
#|  |      ^
#|6 | 
#|exit 1
