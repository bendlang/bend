# A def with no parameters given arguments in <...>: the note says it
# takes none, so the fix is the bare name, not (...).

import Base

def Num() -> Type:
  U32

def main() -> Num<U32>:
  7

#|SOME PROOFS FAIL
#|Error:
#|- message  : a declared datatype
#|Location: main
#| 8 | 
#| 9>| def main() -> Num<U32>:
#|   |               ^^^^^^^
#|10 |   7
#|Note: Num is a def with no arguments: write it as Num
#|exit 1
