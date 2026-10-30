# `x+g(y)` fails inside the `+` of a term: no datatype follows. The error points
# at the `+`, not at the next def (#1510)
import Base

def g(y: U32) -> U32:
  y

def add(x: U32, y: U32) -> U32:
  x+g(y)

def main() -> U32:
  add(1, 2)

#|SOME PROOFS FAIL
#|Error:
#|- expected : a quantified datatype after + (an operator takes spaces on both sides and a type: (a + b : T))
#|- observed : '+'
#|Location:
#| 8 | def add(x: U32, y: U32) -> U32:
#| 9>|   x+g(y)
#|   |    ^
#|10 | 
#|exit 1
