# `==` isn't the `=` a binder list wants, so `x+y == 3` gets the spacing error
# too, not one at the second `=` (#1510)
import Base

def add(x: U32, +y: U32) -> U32:
  x+y == 3

def main() -> U32:
  add(1, 2)

#|SOME PROOFS FAIL
#|Error:
#|- expected : '=' (an operator takes spaces on both sides and a type: (a + b : T))
#|- observed : '+'
#|Location:
#|5 | def add(x: U32, +y: U32) -> U32:
#|6>|   x+y == 3
#|  |    ^
#|7 | 
#|exit 1
