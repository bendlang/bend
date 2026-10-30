# inside a tuple, `x+y` gets the same error, at the `+` (#1510)
import Base

def add(x: U32, +y: U32) -> U32 & U32:
  (x+y, 1)

def main() -> U32 & U32:
  add(1, 2)

#|SOME PROOFS FAIL
#|Error:
#|- expected : '=' (an operator takes spaces on both sides and a type: (a + b : T))
#|- observed : '+'
#|Location:
#|4 | def add(x: U32, +y: U32) -> U32 & U32:
#|5>|   (x+y, 1)
#|  |     ^
#|6 | 
#|exit 1
