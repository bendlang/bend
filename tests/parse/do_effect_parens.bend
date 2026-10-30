# A do block whose effect takes its arguments in (...), as a type does:
# the error expects the '<' and shows how the do block is written.

import Base

def main() -> IO(Unit):
  do IO(Unit):
    IO.print("hello")

#|SOME PROOFS FAIL
#|Error:
#|- expected : '<' (a do block is written do IO<...>:)
#|- observed : '('
#|Location:
#|6 | def main() -> IO(Unit):
#|7>|   do IO(Unit):
#|  |        ^
#|8 |     IO.print("hello")
#|exit 1
