# annotated but glued, `1+x` still reads `+x` as a binder (#1510)
import Base

def add(x: U32) -> U32:
  (1+x : U32)

def main() -> U32:
  add(1)

#|SOME PROOFS FAIL
#|Error:
#|- expected : '=' (an operator takes spaces on both sides and a type: (a + b : T))
#|- observed : '+'
#|Location:
#|4 | def add(x: U32) -> U32:
#|5>|   (1+x : U32)
#|  |     ^
#|6 | 
#|exit 1
