# `x+y` reads `+y` as a reusable binder, so the statement wants `=`; the
# error points at the `+`, not at the next def (#1510)
import Base

def add(x: U32, +y: U32) -> U32:
  x+y

def main() -> U32:
  add(1, 2)

#|SOME PROOFS FAIL
#|Error:
#|- expected : '=' (an operator takes spaces on both sides and a type: (a + b : T))
#|- observed : '+'
#|Location:
#|5 | def add(x: U32, +y: U32) -> U32:
#|6>|   x+y
#|  |    ^
#|7 | 
#|exit 1
