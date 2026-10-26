# A def given arguments in <...>, the syntax of a datatype's: the error
# notes that the name is a def, which takes its arguments in (...).

import Base

def Twice(A: Type) -> Type:
  A & A

def main() -> Twice<U32>:
  (1, 2)

#|SOME PROOFS FAIL
#|Error:
#|- message  : a declared datatype
#|Location: main
#| 8 | 
#| 9>| def main() -> Twice<U32>:
#|   |               ^^^^^^^^^
#|10 |   (1, 2)
#|Note: Twice is a def: write its arguments as ()
#|exit 1
