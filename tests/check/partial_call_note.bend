# a call with too few arguments, where a non-function is expected, says
# so; the observed type already names what is missing.
import Base

def add2(a: U32, b: U32) -> U32:
  U32.add(a, b)

def main() -> U32:
  add2(1)

#|SOME PROOFS FAIL
#|Error:
#|- expected : U32
#|- observed : @b:U32 -> U32
#|Location: main
#| 8 | def main() -> U32:
#| 9>|   add2(1)
#|   |   ^^^^^^^
#|10 |
#|Note: this call is missing arguments.
#|exit 1
