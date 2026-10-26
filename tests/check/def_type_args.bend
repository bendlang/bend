# A def given arguments in <...>, the syntax of a datatype's: the error
# says the name is a def and how a def is applied, not that it is unknown.

import Base

def Twice(A: Type) -> Type:
  A & A

def main() -> Twice<U32>:
  (1, 2)

#|SOME PROOFS FAIL
#|Error:
#|- message  : a declared datatype (Twice is a def, applied as Twice(...))
#|Location: main
#| 8 | 
#| 9>| def main() -> Twice<U32>:
#|   |               ^^^^^^^^^
#|10 |   (1, 2)
#|exit 1
